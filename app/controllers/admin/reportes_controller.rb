class Admin::ReportesController < Admin::BaseController
  def index
    # Base: solo compras completadas (con pago confirmado)
    @compras = Compra.includes(:boletos, :pago, :user, zonas: :evento)
                     .where(estado: "completado")

    # ── Filtro por fechas ───────
    if params[:fecha_inicio].present?
      @compras = @compras.where("compras.created_at >= ?", params[:fecha_inicio].to_date.beginning_of_day)
    end

    if params[:fecha_fin].present?
      @compras = @compras.where("compras.created_at <= ?", params[:fecha_fin].to_date.end_of_day)
    end

    # ── Filtro por evento (incluye eventos eliminados con soft-delete) ─────
    if params[:evento_id].present?
      @compras = @compras.joins(boletos: :zona).where(zonas: { evento_id: params[:evento_id] }).distinct
    end

    # ── Totales para las tarjetas de resumen ───────────────────────────────
    ids_limpios = @compras.pluck(:id).uniq
    @total_ingresos = Compra.where(id: ids_limpios).sum(:precio_total).to_f
    @total_boletos  = Boleto.where(compra_id: ids_limpios).count
    @total_compras  = ids_limpios.size

    # ── Tabla agrupada por evento ──────────────────────────────────────────
    # Incluimos Evento.unscoped para que los eventos con soft-delete
    # (deleted_at no nulo) también aparezcan en el reporte histórico.
    if params[:fecha_inicio].present? || params[:fecha_fin].present? || params[:evento_id].present?
      eventos = Evento.unscoped.includes(zonas: :boletos)
      eventos = eventos.where(id: params[:evento_id]) if params[:evento_id].present?

      @reporte_eventos = eventos.map do |evento|
        compra_ids = Compra.where(estado: "completado")
                          .joins(boletos: :zona)
                          .where(zonas: { evento_id: evento.id })

        if params[:fecha_inicio].present?
          compra_ids = compra_ids.where("compras.created_at >= ?", params[:fecha_inicio].to_date.beginning_of_day)
        end
        if params[:fecha_fin].present?
          compra_ids = compra_ids.where("compras.created_at <= ?", params[:fecha_fin].to_date.end_of_day)
        end

        compra_ids = compra_ids.distinct.pluck(:id)

        vendidos  = Boleto.joins(:zona).where(zonas: { evento_id: evento.id })
                          .where(compra_id: compra_ids).count
        ingresos  = Compra.where(id: compra_ids).sum(:precio_total).to_f
        capacidad = evento.zonas.sum(:capacidad)

        {
          nombre:    evento.nombre,
          eliminado: evento.eliminado?,   # para marcar visualmente en la vista
          vendidos:  vendidos,
          capacidad: capacidad,
          ingresos:  ingresos
        }
      end.select { |row| row[:vendidos] > 0 || params[:evento_id].present? }
    else
      @reporte_eventos = []
    end
  end

  def export
    @compras = Compra.includes(:user, :pago, boletos: { zona: :evento })
                     .where(estado: "completado")
                     .order(created_at: :desc)

    if params[:fecha_inicio].present?
      @compras = @compras.where("compras.created_at >= ?", params[:fecha_inicio].to_date.beginning_of_day)
    end
    if params[:fecha_fin].present?
      @compras = @compras.where("compras.created_at <= ?", params[:fecha_fin].to_date.end_of_day)
    end
    if params[:evento_id].present?
      @compras = @compras.joins(boletos: :zona).where(zonas: { evento_id: params[:evento_id] }).distinct
    end

    respond_to do |format|
      format.html
      format.xlsx do
        response.headers["Content-Disposition"] =
          "attachment; filename=\"reporte_flowarena_#{Time.now.strftime('%Y%m%d_%H%M')}.xlsx\""
      end
      format.pdf do
        render pdf:         "Reporte_FlowArena_#{Time.now.to_i}",
               template:    "admin/reportes/export",
               formats:     [ :html ],
               layout:      "pdf",
               disposition: "attachment"
      end
    end
  end
end