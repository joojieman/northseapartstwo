class CreatePositions < MainMigration
  def change
    create_table :positions, :id => false    do |t|
      common_set_one(t)
      t.string :department_id,limit: 36, :required => true
    end
  end
end
