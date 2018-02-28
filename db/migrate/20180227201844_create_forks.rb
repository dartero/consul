class CreateForks < ActiveRecord::Migration
  def change
    create_table :forks do |t|
      t.string :name
      t.string :repo
      t.string :website
    end
  end
end
