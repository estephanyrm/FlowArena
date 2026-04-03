# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_27_043425) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "boletos", force: :cascade do |t|
    t.string "codigo_qr"
    t.bigint "compra_id", null: false
    t.datetime "created_at", null: false
    t.datetime "fecha_generacion"
    t.datetime "updated_at", null: false
    t.boolean "usado"
    t.bigint "zona_id", null: false
    t.index ["compra_id"], name: "index_boletos_on_compra_id"
    t.index ["zona_id"], name: "index_boletos_on_zona_id"
  end

  create_table "compras", force: :cascade do |t|
    t.integer "cantidad"
    t.datetime "created_at", null: false
    t.datetime "fecha_compra"
    t.string "numero_orden"
    t.decimal "precio_total"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_compras_on_user_id"
  end

  create_table "eventos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.string "estado"
    t.date "fecha"
    t.time "hora"
    t.string "imagen"
    t.string "nombre"
    t.datetime "updated_at", null: false
  end

  create_table "pagos", force: :cascade do |t|
    t.bigint "compra_id", null: false
    t.datetime "created_at", null: false
    t.boolean "estado"
    t.datetime "fecha_pago"
    t.decimal "monto"
    t.string "referencia"
    t.datetime "updated_at", null: false
    t.index ["compra_id"], name: "index_pagos_on_compra_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "reportes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "fecha_generacion"
    t.string "tipo"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "zonas", force: :cascade do |t|
    t.integer "capacidad"
    t.datetime "created_at", null: false
    t.integer "cupos_disponibles"
    t.bigint "evento_id", null: false
    t.string "nombre"
    t.integer "precio_cents"
    t.datetime "updated_at", null: false
    t.index ["evento_id"], name: "index_zonas_on_evento_id"
  end

  add_foreign_key "boletos", "compras"
  add_foreign_key "boletos", "zonas"
  add_foreign_key "compras", "users"
  add_foreign_key "pagos", "compras"
  add_foreign_key "profiles", "users"
  add_foreign_key "zonas", "eventos"
end
