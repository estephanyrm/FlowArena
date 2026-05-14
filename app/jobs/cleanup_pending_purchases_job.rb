class CleanupPendingPurchasesJob < ApplicationJob
  queue_as :default

  def perform
    compras = Compra.where(estado: "pendiente")
                    .where("created_at < ?", 2.minutes.ago)

    Rails.logger.info "Eliminando #{compras.count} compras pendientes antiguas"

    compras.destroy_all
  end
end
