class AddUniqueIndexToUsersUsername < ActiveRecord::Migration[8.0]
  def change
    # Remove duplicates before enforcing uniqueness (safety)
    existing_dupes = execute("SELECT username FROM users GROUP BY username HAVING COUNT(*) > 1;")

    existing_dupes.each do |row|
      username = row["username"]
      users = execute("SELECT id FROM users WHERE username = '#{username}' ORDER BY created_at;")
      
      # Keep the first, rename the rest
      users.to_a.drop(1).each do |user|
        execute("UPDATE users SET username = CONCAT(username, '_', id) WHERE id = #{user['id']};")
      end
    end

    add_index :users, :username, unique: true
  end
end
