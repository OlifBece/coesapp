class TipoEstadoCalificacion < ApplicationRecord
	has_many :inscripciones_en_secciones
	accepts_nested_attributes_for :inscripciones_en_secciones
end
