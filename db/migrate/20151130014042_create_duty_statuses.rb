class CreateDutyStatuses < ActiveRecord::Migration
  def change
    create_table :duty_statuses, :id => false  do |t|

      t.string :id, limit: 36, primary: true, null: false
      t.string :description, :limit => 256
      t.boolean :label, :limit => 64
      t.string :employee_id,limit: 36, :required => true

      t.timestamps null: false
    end
  end
end
