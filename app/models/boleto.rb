class Boleto < ApplicationRecord
  belongs_to :zona
  belongs_to :compra
end
