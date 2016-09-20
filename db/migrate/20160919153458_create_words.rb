class CreateWords < ActiveRecord::Migration[5.0]
  def up
    create_table :words do |t|
      #Private system maintained attributes

      #Public user-set attributes
      t.column :word,        :string, null: false, unique: true
      t.column :anagram_key, :string, null: false, unique: false

      #Foreign keys

      #Record keeping attributes
      t.column :created_at, :datetime
      t.column :updated_at, :datetime

    end

    #Indexes
    add_index(:words, :anagram_key, name: :word_anagram_key)
  end

  def down
    drop_table :words

    remove_index(:words, name: :word_anagram_key)
  end

end
