class CleanupPendingPurchasesJob < ApplicationJob
  queue_as :default

  def perform
    compras = Compra.where(estado: "pendiente", user_id: nil)
                    .where("created_at < ?", 2.minutes.ago)

    Rails.logger.info "Eliminando #{compras.count} compras pendientes de invitados"

    compras.destroy_all
  end
end