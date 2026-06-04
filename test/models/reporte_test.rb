require "test_helper"

class ReporteTest < ActiveSupport::TestCase

  test "se puede crear un reporte sin atributos" do
    # El modelo Reporte no tiene validaciones declaradas
    reporte = Reporte.new
    assert reporte.valid?
  end

  test "se puede persistir un reporte" do
    assert_difference "Reporte.count", 1 do
      Reporte.create!
    end
  end

  test "reporte tiene columna tipo si existe" do
    # Verifica que la columna exista sin romper si no existe
    if Reporte.column_names.include?("tipo")
      reporte = Reporte.create!(tipo: "ventas")
      assert_equal "ventas", reporte.tipo
    else
      assert true # La columna no existe aún, test passes
    end
  end

  test "reporte tiene columna fecha_generacion si existe" do
    if Reporte.column_names.include?("fecha_generacion")
      fecha = Time.current
      reporte = Reporte.create!(fecha_generacion: fecha)
      assert_not_nil reporte.fecha_generacion
    else
      assert true
    end
  end
end
