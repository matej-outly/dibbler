class CreateSlugs < ActiveRecord::Migration
  def change
    create_table :slugs do |t|
      t.timestamps null: true
      t.string :locale, index: true
      # t.string :filter, index: true # Optional column distinguishing application variant
      t.string :original, index: true
      t.string :translation, index: true
    end
  end
end
