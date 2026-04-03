class Admin::ReportesController < Admin::BaseController
  def index
    @reportes = Reporte.all
    @reportes = @reportes.where("created_at >= ?", params[:fecha_inicio]) if params[:fecha_inicio].present?
    @reportes = @reportes.where("created_at <= ?", params[:fecha_fin].to_date.end_of_day) if params[:fecha_fin].present?
  end

  def export
    @compras = Compra.all
    respond_to do |format|
      format.html  # Para ver la página en el navegador
      format.xlsx {
        response.headers['Content-Disposition'] = 'attachment; filename="reporte.xlsx"'
      }
  
      format.pdf do
        render pdf: "Reporte_FlowArena_#{Time.now.to_i}",
              template: "admin/reportes/export",
              formats: [:html],
              layout: 'pdf',
              disposition: 'attachment'
      end
    end
  end
end
