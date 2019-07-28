class Grado < ApplicationRecord
	# ASOCIACIONES:
	belongs_to :escuela
	belongs_to :estudiante

	# has_many :inscripcionsecciones, foreign_key: [:escuela_id, :estudiante_id]

	scope :no_retirados, -> {where "estado != 3"}
	scope :cursadas, -> {where "estado != 3"}
	scope :aprobadas, -> {where "estado = 1"}
	scope :sin_equivalencias, -> {joins(:seccion).where "secciones.tipo_seccion_id != 'EI' and secciones.tipo_seccion_id != 'EE'"} 
	scope :por_equivalencia, -> {joins(:seccion).where "secciones.tipo_seccion_id = 'EI' or secciones.tipo_seccion_id = 'EE'"}
	scope :por_equivalencia_interna, -> {joins(:seccion).where "secciones.tipo_seccion_id = 'EI'"}
	scope :por_equivalencia_externa, -> {joins(:seccion).where "secciones.tipo_seccion_id = 'EE'"}
	scope :total_creditos_inscritos, -> {joins(:asignatura).sum('asignaturas.creditos')}

	scope :culminado_en_periodo, lambda { |periodo_id| where "culminacion_periodo_id = ?", periodo_id}

	scope :de_las_escuelas, lambda {|escuelas_ids| where("escuela_id IN (?)", escuelas_ids)}

	enum estado: [:pregrado, :tesista, :posible_graduando, :graduando, :graduado]

	def inscripciones
		Inscripcionseccion.joins(:escuela).where("estudiante_id = ? and escuelas.id = ?", estudiante_id, escuela_id)
	end

	# Así debe ser inscripciones
	# def inscripciones
	# 	Inscripcionseccion.where("estudiante_id = ? and escuelas_id = ?", estudiante_id, escuela_id)
	# end


	def total_creditos_cursados periodos_ids = nil
		if periodos_ids
			inscripciones.total_creditos_cursados_en_periodos periodos_ids
		else
			inscripciones.total_creditos_cursados
		end
	end

	def total_creditos_aprobados periodos_ids = nil
		if periodos_ids
 			inscripciones.total_creditos_aprobados_en_periodos periodos_ids
 		else
 			inscripciones.total_creditos_aprobados
 		end
	end

	def eficiencia periodos_ids = nil 
        cursados = self.total_creditos_cursados periodos_ids
        aprobados = self.total_creditos_aprobados periodos_ids
		(cursados and cursados > 0) ? (aprobados.to_f/cursados.to_f).round(4) : 0.0
	end

	def promedio_simple periodos_ids = nil
		if periodos_ids
			aux = inscripciones.de_los_periodos(periodos_ids).cursadas
		else
			aux = inscripciones.cursadas
		end

        (aux and aux.count > 0 and !aux.average('calificacion_final').nil?) ? aux.average('calificacion_final').round(4) : 0.0

	end

	def promedio_ponderado periodos_ids = nil
		if periodos_ids
			aux = inscripciones.de_los_periodos(periodos_ids).ponderado
		else
			aux = inscripciones.ponderado
		end
		cursados = self.total_creditos_cursados periodos_ids

		cursados > 0 ? (aux.to_f/cursados.to_f).round(4) : 0.0
	end


	def inscrito_en_periodo? periodo_id
		(inscripciones.del_periodo(periodo_id)).count > 0
	end


	def id
		"#{escuela_id}-#{estudiante_id}"
	end

	def ultimo_plan
		hp = estudiante.historialplanes.por_escuela(escuela_id).order('periodo_id DESC').first
		hp ? hp.plan : nil
	end

	def descripcion_ultimo_plan
		plan = ultimo_plan
		if plan
			plan.descripcion_filtro
		else
			'Sin Plan Asignado'
		end
	end

	# private

	# def actualizar_estado_inscripciones
	# 	if asignatura.tipoasignatura_id.eql? Tipoasignatura::PROYECTO
	# 		if self.sin_calificar?
	# 			grado.update(estado :tesista)
	# 		elsif self.retirado? or self.aplazado
	# 			grado.update(estado :pregrado)
	# 		elsif self.aprobado?
	# 			grado.update(estado 'posible_graduando')
	# 		end
	# 	end
	# end	


end