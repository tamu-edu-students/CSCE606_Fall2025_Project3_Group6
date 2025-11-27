class AddWatchHistoryToWatchLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # add column (allow null during backfill)
    add_reference :watch_logs, :watch_history, foreign_key: true, index: true, type: :bigint

    # create per-user watch_history rows for any users referenced by existing watch_logs
    execute(<<-SQL.squish)
      INSERT INTO watch_histories (user_id, created_at, updated_at)
      SELECT DISTINCT user_id, NOW(), NOW() FROM watch_logs
      WHERE user_id IS NOT NULL
      ON CONFLICT (user_id) DO NOTHING;
    SQL

    # backfill watch_history_id from watch_histories table
    execute(<<-SQL.squish)
      UPDATE watch_logs
      SET watch_history_id = wh.id
      FROM watch_histories wh
      WHERE watch_logs.user_id = wh.user_id;
    SQL

    # now that rows are backfilled, enforce not-null
    change_column_null :watch_logs, :watch_history_id, false
  end

  def down
    remove_reference :watch_logs, :watch_history, foreign_key: true
  end
end
