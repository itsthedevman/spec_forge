class Initial < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, default: :user  # admin, user, etc.
      t.string :password  # For simplicity in the demo; Do not do this in production
      t.boolean :active, default: true

      t.timestamps
    end

    create_table :api_tokens do |t|
      t.string :token, null: false, index: {unique: true}
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end

    create_table :posts do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.boolean :published, default: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    create_table :comments do |t|
      t.text :content, null: false
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
