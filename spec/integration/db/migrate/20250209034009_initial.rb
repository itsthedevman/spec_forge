class Initial < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, default: :user  # admin, user, etc.
      t.boolean :active, default: true

      t.belongs_to :team

      t.timestamps
    end

    create_table :api_tokens do |t|
      t.string :token, null: false, index: {unique: true}

      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end

    create_table :posts do |t|
      t.string :title, null: false
      t.text :content
      t.string :category
      t.string :status  # draft, published, etc.

      t.belongs_to :author, null: false, foreign_key: {to_table: :users}

      t.timestamps
    end

    create_table :comments do |t|
      t.text :content, null: false

      t.belongs_to :post, null: false
      t.belongs_to :author, null: false, foreign_key: {to_table: :users}

      t.timestamps
    end

    create_table :teams do |t|
      t.string :name, null: false

      t.string :plan_type  # free, pro, enterprise

      t.timestamps
    end

    create_table :reviews do |t|
      t.belongs_to :reviewer, null: false, foreign_key: {to_table: :users}
      t.belongs_to :post, null: false

      t.string :status  # pending, approved, rejected
      t.text :notes

      t.timestamps
    end
  end
end
