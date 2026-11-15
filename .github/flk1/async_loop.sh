# usage: async_loop.sh N [START_SEED] ; runs the pinning test, the dirtying test and the retry test in seeded random order
n=$1; start=${2:-1}; fails=0; ran=0
for s in $(seq $start $((start + n - 1))); do
  ARCONN=sqlite3_ractor SEED=$s bundle exec ruby -Itest -e 'ARGV.shift(0); %w[database_selector_test transactions_test asynchronous_queries_test].each { |f| require File.expand_path("test/cases/#{f}.rb") }' -- --seed $s -n '/^(ActiveRecord::DatabaseSelectorTest#test_can_write_while_reading_from_replicas_if_explicit|TransactionTest#test_checking_in_connection_reenables_lazy_transactions|AsynchronousQueriesTest#test_async_query_retries_connection_failure)$/' > /tmp/o.txt 2>&1
  grep -q '^3 runs' /tmp/o.txt && ran=$((ran+1))
  grep -q '^3 runs, .* 0 failures, 0 errors' /tmp/o.txt || { fails=$((fails+1)); grep -m1 -E 'runs, |Error' /tmp/o.txt; }
done
echo "RESULT $fails failing of $n runs ($ran ran 3 tests)"
