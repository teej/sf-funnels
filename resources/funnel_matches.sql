CREATE OR REPLACE FUNCTION funnel_matches ( EVENT_CODE VARCHAR, EPOCH_MS FLOAT, FUNNEL VARCHAR )    
RETURNS TABLE (HAS_MATCH BOOLEAN, MATCHES ARRAY)
LANGUAGE JAVASCRIPT
AS $$
  {
    processRow: function (row, rowWriter, context) {

        // If we already found a match, end early
        if (!this.has_complete_match) {

            if (this.pattern == null) {
                // Pattern initialization
                this.initializePattern(row.FUNNEL);
            }
            
            const event_code = row.EVENT_CODE;
            const ts = row.EPOCH_MS;

            // When out of total session window (sum(stepwise time)) e.g. 3min
            // => then reset all marks, cursors, and last seens
            const should_reset = (ts - this.last_seen >= this.total_time_limit);

            // When out of stepwise window, attempt fast forward
            const should_fast_foward = (this.pattern_cursor > 0 && !this.row_is_on_time(ts));

            if (should_reset) {
                this.pattern_cursor = 0;
                this.resetMemory();
            } else if (should_fast_foward) {

                // The current row is out of the acceptable time window. Before throwing it out,
                // attempt to fast forward our marks
                let prior = null;
                let last_valid_step = null;
                for (let k = 0; k < this.pattern_cursor; k++) {

                    let last_seen_at_k = this.last_seen_at_k[k];
                    if (k == 0 || (last_seen_at_k > prior && last_seen_at_k < prior + this.window_at_k(k - 1))) {
                        this.marks[k] = last_seen_at_k;
                        last_valid_step = k;
                    } else {
                        this.marks[k] = null;
                    }
                    prior = last_seen_at_k;
                }
                // rewind cursor
                this.pattern_cursor = last_valid_step + 1;
            }

            
            const row_matches_current_step = (event_code == this.current_step());
            const row_matches_prior_step = (event_code == this.prior_step());

            if (row_matches_current_step) {
                // If we match current step, determine if we should advance 
                
                let event_is_on_time = (this.pattern_cursor == 0 || this.row_is_on_time(ts));

                if (event_is_on_time) {
                    // record the match, update mark & advance to next step
                    this.matches[this.pattern_cursor] = true;
                    // Complete match, we are done
                    if (this.pattern_cursor == this.pattern.length - 1) {
                        this.has_complete_match = true;
                        return;
                    }
                    this.marks[this.pattern_cursor] = ts;
                    this.pattern_cursor += 1;
                }

            } else if (this.pattern_cursor == 1 && row_matches_prior_step) {
                // Special case: if cursor == 1, we can always advance the mark for step 0
                this.marks[0] = ts;

            } else if (this.pattern_cursor > 1 && row_matches_prior_step) {
                // If we match prior step, see if we can push that steps mark forward

                // Check the deadline for the prior step
                let deadline = this.last_seen_at_k[this.pattern_cursor - 2] + this.prior_window();

                if (ts < deadline) {
                    // push mark up to deadline
                    this.marks[this.pattern_cursor - 1] = ts;
                    this.marks[this.pattern_cursor - 2] = this.last_seen_at_k[this.pattern_cursor - 2];
                }
                
            }

            // Update last seen
            this.last_seen = ts;
            for (let k = 0; k <= this.pattern_cursor; k++) {
                if (event_code == this.pattern[k][0]) {
                    this.last_seen_at_k[k] = ts;
                }
            }
            
        }
    },

    finalize: function (rowWriter, context) {
        rowWriter.writeRow({
            HAS_MATCH: this.has_complete_match,
            MATCHES: this.matches
        });
    },
    
    initialize: function(argumentInfo, context) {

        const PATTERN_SEPARATORS = {
          '>':            60 * 1000, // 1 minute
          '›':       15 * 60 * 1000, // 15 minute
          '»':       60 * 60 * 1000, // 1 hour
          '⇉':     8*60 * 60 * 1000, // 8 hours
          '⇶':  1*24*60 * 60 * 1000, // 1 day
          '➤':  7*24*60 * 60 * 1000, // 7 days
          '❯': 30*24*60 * 60 * 1000, // 30 days
        }

        this._version = '0.0.1';

        this.has_complete_match = false;
        this.matches = null;
        this.user_id = null;
        this.pattern = null;
        this.pattern_cursor = null;
        this.marks = null;
        this.last_seen = null;
        this.last_seen_at_k = null;

        this.initializePattern = function initializePattern(pattern_str) {

            let tokens = pattern_str.split('');

            this.pattern = [[tokens[0], 0]];
            this.total_time_limit = 0;

            for (let i = 1; i < tokens.length; i += 2) {
                let time_limit = PATTERN_SEPARATORS[tokens[i]];
                let event_code = tokens[i+1];
                this.pattern.push([event_code, time_limit])
                this.total_time_limit += time_limit;
            }

            // this.pattern = pattern_str.split(">");
            this.pattern_cursor = 0;
            this.matches = Array.from({length: this.pattern.length}, () => false);
            this.resetMemory();
        }

        this.resetMemory = function resetMemory() {
            this.marks = Array.from({length: this.pattern.length}, () => null);
            this.last_seen_at_k = Array.from({length: this.pattern.length}, () => null);
        }

        this.leading_mark = function leading_mark() {
            if (this.pattern_cursor == 0)
                return null;
            return this.marks[this.pattern_cursor - 1];
        }

        // Step helpers

        this.current_step = function current_step() {
            return this.pattern[this.pattern_cursor][0];
        }

        this.prior_step = function prior_step() {
            if (this.pattern_cursor == 0)
                return null;
            return this.pattern[this.pattern_cursor - 1][0];
        }

        this.current_window = function current_window() {
            return this.pattern[this.pattern_cursor][1];
        }

        this.prior_window = function prior_window() {
            return this.pattern[this.pattern_cursor - 1][1];
        }

        this.window_at_k = function window_at_k(k) {
            return this.pattern[k][1];
        }

        this.row_is_on_time = function row_is_on_time(ts) {
            return ts - this.leading_mark() < this.current_window();
        }
    }
}
$$
