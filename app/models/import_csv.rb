
class ImportCsv

	# def self.preview url
		
	# 	require 'csv'    

	# 	csv_text = File.read(url)
		
	# 	return CSV.parse(csv_text, headers: true, encoding: 'iso-8859-1:utf-8')
	# end

	def self.importar_estudiantes file, escuela_id, plan_id, periodo_id, grado
		require 'csv'

		csv_text = File.read(file)

		total_agregados = 0
		usuarios_existentes = []
		estudiantes_existentes = []
		estudiantescuelas_existentes = []
		usuarios_no_agregados = []
		estudiantes_no_agregados = []
		total_planes_agregados = 0
		total_planes_no_agregados = 0

		csv = CSV.parse(csv_text, headers: true, encoding: 'iso-8859-1:utf-8')
		# csv.each do |row|
		csv.group_by{|row| row['ci']}.values.each do |row|

			begin
				# if profe = Profesor.where(usuario_id: row.field(0))
				hay_usuario = false
				row = row[0]
				row['ci'].strip!
				row['ci'].delete! '^0-9'
				plan_id = row['plan_id'] #if plan_id.nil?
				# tipo_ingreso = row['tipo_ingreso'] ? row['tipo_ingreso'] : Grado::TIPO_INGRESOS[0]

				if usuario = Usuario.where(ci: row['ci']).limit(1).first
					usuarios_existentes << usuario.ci
					hay_usuario = true
				else
					usuario = Usuario.new
					usuario.ci = row['ci']
					usuario.password = usuario.ci

					if row['nombres_apellidos'] 
						nombres_apellidos = separar_cadena row['nombres y apellidos']
						usuario.apellidos = nombres_apellidos[0]
						usuario.email = nombres_apellidos[1]
					else
						usuario.apellidos = limpiar_cadena row['apellidos']
						usuario.nombres = limpiar_cadena row['nombres']
					end
					usuario.telefono_movil = row['telefono']
					usuario.email = limpiar_cadena row['email'] unless row['email'].blank?
					usuario.telefono_habitacion = row['telefono_habitacion']
					if usuario.save
						hay_usuario = true
						p usuario.to_json
					else
						usuarios_no_agregados << row['ci']
					end
				end

				if hay_usuario
					p "HAY USUARIO"
					hay_estudiante = false
					if estudiante = Estudiante.where(usuario_id: usuario.ci ).first
						estudiantes_existentes << estudiante.usuario_id
						hay_estudiante = true
					else
						estudiante = Estudiante.new
						estudiante.usuario_id = usuario.ci
						# estudiante.escuela_id = escuela_id
						if estudiante.save
							hay_estudiante = true
						else
							estudiantes_no_agregados << usuario.ci
						end
					end

					if hay_estudiante
						p "GRADO: #{grado['estado_inscripcion']}, #{grado['tipo_ingreso']}, #{grado[:estado]}"
						p "HAY ESTUDIANTE"

						if estudiante.grados.where(escuela_id: escuela_id).first
							estudiantescuelas_existentes << estudiante.id
						else
							p "ESCUELA ESTUDIANTE AGREGADO"
							total_agregados += 1 if estudiante.grados.create!(escuela_id: escuela_id, tipo_ingreso: grado['tipo_ingreso'], estado_inscripcion: grado['estado_inscripcion'], estado: grado[:estado])
						end
						estudiante.historialplanes.destroy_all
						if plan_id and !estudiante.historialplanes.where(plan_id: plan_id, periodo_id: periodo_id).any?
							hp = Historialplan.new
							grado = estudiante.grados.where(escuela_id: escuela_id).first
							p "ESTUDIANTE CI: #{estudiante.id}"
							hp.plan_id = plan_id
							hp.periodo_id = periodo_id
							# hp.estudiante_id = estudiante.id
							# hp.escuela_id = escuela_id
							hp.grado = grado
							if hp.save
								total_planes_agregados += 1
							else
								total_planes_no_agregados += 1
							end
						end

					end
				end

			end
		end
		resumen = "</br><b>Resumen:</b> 
			</br></br>Total de registros a procesar: <b>#{csv.count}</b>
			</br></br>Total Estudiantes Agregados: <b>#{total_agregados}</b><hr></hr>
			Total Usuarios Existentes: <b>#{usuarios_existentes.size}</b><hr></hr>
			Total Estudiantes Existentes: <b>#{estudiantes_existentes.size}</b><hr></hr>

			Total Estudiantes No Agregados: <b>#{estudiantes_no_agregados.size}</b>
			</br><i>Detalle:</i></br> #{estudiantes_no_agregados.to_sentence}<hr></hr>

			Total Carreras Existentes: <b>#{estudiantescuelas_existentes.size}</b><hr></hr>

			Total Usuarios No Agregados: <b>#{usuarios_no_agregados.size}</b>
			</br><i>Detalle:</i></br> #{usuarios_no_agregados.to_sentence}
			</br>Total Planes Agregados: <b>#{total_planes_agregados}</b>
			</br>Total Planes No Agregados o Existentes: <b>#{total_planes_no_agregados}</b>"

		return "Proceso de importación completado. #{resumen}"
	end

	def self.importar_profesores file
		require 'csv'

		csv_text = File.read(file)

		total_agregados = 0
		usuarios_existentes = []
		profesores_existentes = []
		usuarios_no_agregados = []
		profes_no_agregados = []

		csv = CSV.parse(csv_text, headers: true, encoding: 'iso-8859-1:utf-8')
		csv.each do |row|
			begin
				row['ci'].delete! '^0-9'
				row['ci'].strip!
				# if profe = Profesor.where(usuario_id: row.field(0))
				if profe = Profesor.where(usuario_id: row['ci']).first
					profesores_existentes << profe.usuario_id
				elsif usuario = Usuario.where(ci: row['ci']).first
					usuarios_existentes << usuario.ci
					profe = Profesor.new
					profe.departamento_id = row['departamento_id']
					profe.usuario_id = usuario.ci
					total_agregados += 1 if profe.save
				else
					usuario = Usuario.new
					usuario.ci = row['ci']
					usuario.password = usuario.ci
					usuario.nombres = row['nombres']
					usuario.apellidos = row['apellidos']
					usuario.email = row['email']
					usuario.telefono_movil = row['telefono']
					if usuario.save
						profe = Profesor.new
						profe.departamento_id = row['departamento_id']
						profe.usuario_id = usuario.ci
						if profe.save
							total_agregados += 1
						else
							profes_no_agregados << profe.usuario_id
						end
					else
						usuarios_no_agregados << row['ci']
					end
				end
			end
		end

		resumen = "</br><b>Resumen:</b> 
			</br></br>Total Profesores Agregados: <b>#{total_agregados}</b><hr></hr>
			Total Profesores Existentes: <b>#{profesores_existentes.size}</b>
			</br><i>Detalle:</i></br>#{profesores_existentes.to_sentence}<hr></hr>
			Total Usuarios Existentes (Se les creó el rol de profesor): <b>#{usuarios_existentes.size}</b>
			</br><i>Detalle:</i></br>#{usuarios_existentes.to_sentence}<hr></hr>
			Total Profesores No Agregados (Se creó el usuario pero no el profesor): <b>#{profes_no_agregados.count}</b>
			</br><i>Detalle:</i></br> #{profes_no_agregados.to_sentence}<hr></hr>
			Total Usuarios No Agregados: <b>#{usuarios_no_agregados.count}</b>
			</br><i>Detalle:</i></br> #{usuarios_no_agregados.to_sentence}"

		return "Proceso de importación completado. #{resumen}"
	end

	def self.importar_inscripciones file, escuela_id, periodo_id
		require 'csv'

		csv_text = File.read(file)
		total_inscritos = 0
		total_existentes = 0
		estudiantes_no_inscritos = []
		total_nuevas_secciones = 0
		secciones_no_creadas = []
		estudiantes_inexistentes = []
		asignaturas_inexistentes = []
		total_calificados = 0
		total_aprobados = 0
		total_aplazados = 0
		total_retirados = 0
		total_no_calificados = 0

		estudiantes_sin_grado = []

		csv = CSV.parse(csv_text, headers: true, encoding: 'iso-8859-1:utf-8')
			csv.each do |row|
				begin
					row.field(0).delete! '^0-9'
					row.field(0).strip!
					row.field(1).strip!
					row.field(2).strip! if row.field(2)
					if a = Asignatura.where(id_uxxi: row.field(1)).first
						if periodo_id.nil?
							if row.field(4)
 
								row.field(4).strip!
								row.field(4).upcase!
								
								unless Periodo.where(id: row.field(4)).any?
									return "Error: Periodo '#{row.field(4)}' es inválida. fila: [#{row}]. Revise el archivo e inténtelo nuevamente."
								end

							else
								return 'Error en el periodo_id. Por favor revise el archivo e inténtelo nuevamente.'
							end
							periodo_id = row.field(4)
						end

						unless s = Seccion.where(numero: row.field(2), periodo_id: periodo_id, asignatura_id: a.id).limit(1).first
							total_nuevas_secciones += 1 if s = Seccion.create!(numero: row.field(2), periodo_id: periodo_id, asignatura_id: a.id, tipo_seccion_id: 'NF')
						end

						if s
							estu = Estudiante.where(usuario_id: row.field(0)).first
							unless estu
								estudiantes_inexistentes << row.field(0)
							else
								



								inscrip = s.inscripcionsecciones.where(estudiante_id: row.field(0)).first
								unless inscrip
									inscrip = Inscripcionseccion.new
									escuelaperiodo = Escuelaperiodo.where(periodo_id: periodo_id, escuela_id: a.escuela.id).first

									unless inscrip_escuela_period = estu.inscripcionescuelaperiodos.where(escuelaperiodo_id: escuelaperiodo.id).first

										inscrip_escuela_period = Inscripcionescuelaperiodo.create!(estudiante_id: row.field(0), escuelaperiodo_id: escuelaperiodo.id, tipo_estado_inscripcion_id: 'INS')
									end

									inscrip.inscripcionescuelaperiodo_id = inscrip_escuela_period.id

									grado = estu.grados.where(escuela_id: escuela_id).first

									unless grado
										estudiantes_sin_grado << estu.id
									else
										inscrip.seccion_id = s.id
										inscrip.estudiante_id = estu.id

										inscrip.escuela_id = escuela_id
										# inscrip.grado = grado



										inscrip.pci = true unless estu.grados.where(escuela_id: escuela_id).any?
											
										if inscrip.save!
											total_inscritos += 1
										else
											estudiantes_no_inscritos << row.field(0)
										end
									end
								else
									total_existentes += 1
								end

								# CALIFICAR:
								if row.field(3) and ! row.field(3).blank?
									row.field(3).strip!
									if row.field(3).eql? 'RT'
										inscrip.estado = :retirado
										inscrip.tipo_calificacion_id = TipoCalificacion::FINAL 
									elsif inscrip.asignatura and inscrip.asignatura.absoluta?
										if row.field(3).eql? 'A'
											inscrip.estado = :aprobado
										else
											inscrip.estado = :aplazado
										end
										inscrip.tipo_calificacion_id = TipoCalificacion::FINAL
									else
										inscrip.calificacion_final = row.field(3)
										
										if inscrip.calificacion_final >= 10
											inscrip.estado = :aprobado
										else
											if inscrip.calificacion_final == 0
												inscrip.tipo_calificacion_id = TipoCalificacion::PI 
											else
												inscrip.tipo_calificacion_id = TipoCalificacion::FINAL 
											end
											inscrip.estado = :aplazado
										end
									end

									if inscrip.save!
										total_calificados += 1
										if inscrip.retirado?
											total_retirados += 1
										elsif inscrip.aprobado?
											total_aprobados += 1
										else
											total_aplazados += 1
										end
									else
										total_no_calificados += 1
									end
								end
							end

						else
							secciones_no_creadas << row.to_hash
						end
					else
						asignaturas_inexistentes << row.field(1)
					end
				rescue Exception => e
					return "Error excepcional: #{e.to_sentence}. #{self.resumen total_inscritos, total_existentes, estudiantes_no_inscritos, total_nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados, periodo_id, estudiantes_sin_grado }"
				end
			end
		return "Proceso de importación completado con éxito. #{self.resumen total_inscritos, total_existentes, estudiantes_no_inscritos, total_nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados,periodo_id, estudiantes_sin_grado}"
	end


	def self.importar_estudiantes_e_inscripciones file, periodo_id
		require 'csv'

		csv_text = File.read(file)
		total_inscritos = 0
		total_existentes = 0
		estudiantes_no_inscritos = []
		total_nuevas_secciones = 0
		secciones_no_creadas = []
		estudiantes_inexistentes = []
		asignaturas_inexistentes = []
		total_calificados = 0
		total_aprobados = 0
		total_aplazados = 0
		total_retirados = 0
		total_no_calificados = 0		
		p "RESULTADO".center(200, "=")
		rows = CSV.parse(csv_text, headers: true, encoding: 'iso-8859-1:utf-8')

		rows.group_by{|row| row[2]}.values.each do |asig|
			id_uxxi = limpiar_cadena asig[0][1]
			if a = Asignatura.where(id_uxxi: id_uxxi).first
				asig.group_by{|sec| sec[2]}.each do |seccion|
					seccion_id = seccion[0]

					unless s = Seccion.where(numero: seccion_id, periodo_id: periodo_id, asignatura_id: id_uxxi).limit(1).first
					
						total_nuevas_secciones += 1 if s = Seccion.create!(numero: seccion_id, periodo_id: periodo_id, asignatura_id: id_uxxi, tipo_seccion_id: 'NF')
					end

					if s
						seccion[1].each do |reg|

							if Estudiante.where(usuario_id: reg.field(0)).count <= 0

								estudiantes_inexistentes << reg.field(0)

							else
								inscrip = s.inscripcionsecciones.where(estudiante_id: reg.field(0)).first
								
								unless inscrip
										inscrip = Inscripcionseccion.new
										inscrip.seccion_id = s.id
										inscrip.estudiante_id = reg.field(0)
										
									if inscrip.save
										total_inscritos += 1
									else
										estudiantes_no_inscritos << reg.field(0)
									end
								else
									total_existentes += 1
								end

								# CALIFICAR:
								if reg.field(3) and ! reg.field(3).blank?
									reg.field(3).strip!
									if reg.field(3).eql? 'RT'
										inscrip.estado = :retirado
										inscrip.tipo_calificacion_id = TipoCalificacion::FINAL 
									elsif inscrip.asignatura and inscrip.asignatura.absoluta?
										if reg.field(3).eql? 'A'
											inscrip.estado = :aprobado
										else
											inscrip.estado = :aplazado
										end
										inscrip.tipo_calificacion_id = TipoCalificacion::FINAL
									else
										inscrip.calificacion_final = reg.field(3)
										
										if inscrip.calificacion_final >= 10
											inscrip.estado = :aprobado
										else
											if inscrip.calificacion_final == 0
												inscrip.tipo_calificacion_id = TipoCalificacion::PI 
											else
												inscrip.tipo_calificacion_id = TipoCalificacion::FINAL 
											end
											inscrip.estado = :aplazado
										end
									end

									if inscrip.save
										total_calificados += 1
										if inscrip.retirado?
											total_retirados += 1
										elsif inscrip.aprobado?
											total_aprobados += 1
										else
											total_aplazados += 1
										end
									else
										total_no_calificados += 1
									end
								end
							end







						end

					else
						secciones_no_creadas << row.to_hash
					end						



				end 
			else
				asignaturas_inexistentes << id_uxxi
			end
		end
  		# puts [group.first['ID'], group.map{|r| r['COMMENT']} * ' '] * ' | '
		
		# rows.each do |row|
		# 	begin
		# 		row = limpiar_fila row
		# 		#p self.separar_cadena(row.field(1))
		# 	rescue Exception => e
		# 		return "Error excepcional: #{e.to_sentence}"
		# 	end
		# end
		p "=".center(200, "=")
	end

	private


	def self.resumen inscritos, existentes, no_inscritos, nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados, periodo_id, estudiantes_sin_grado
		
		aux = ""
		aux = "</br>
			<b>Resumen:</b>
			</br></br>Período: <b>#{periodo_id}</b>
			</br></br>Total Nuevos Inscritos: <b>#{inscritos}</b>
			</br>Total Existentes: <b>#{existentes}</b>
			</br>Total Nuevas Secciones: <b>#{nuevas_secciones}</b>
			<hr></hr>Total Secciones No Creadas: <b>#{secciones_no_creadas.count}</b>
			<hr></hr>Total Asignaturas Inexistentes: <b>#{asignaturas_inexistentes.uniq.count}</b>
			</br><i>Detalle últimos 50:</i></br> #{asignaturas_inexistentes.uniq.to_sentence}
			<hr></hr>Total Estudiantes Inexistentes: <b>#{estudiantes_inexistentes.uniq.count}</b>
			<hr></hr>Total No registrados en la escuela: <b>#{estudiantes_sin_grado.uniq[0..50].to_sentence}</b>
			</br><i>Detalle últimos 50:</i></br> #{estudiantes_inexistentes.uniq[0..50].to_sentence}"

		if total_calificados and total_calificados.to_i > 0
			aux += "<hr></hr>Calificaciones:"
			aux += "</br>Total Estudiantes Calificados: <b>#{total_calificados}</b>"
			aux += "</br>Total Estudiantes Aprobados: <b>#{total_aprobados}</b>"
			aux += "</br>Total Estudiantes Aplazados: <b>#{total_aplazados}</b>"
			aux += "</br>Total Estudiantes Retirados: <b>#{total_retirados}</b>"
			aux += "</br>Total Estudiantes No Calificados: <b>#{total_no_calificados}</b>"

		end
		return aux
	end

	def crear_usuario usuario_params
		hay_usuario = false
		if usuario = Usuario.where(ci: usuario_params[:ci]).limit(1).first
			hay_usuario = true
		else
			usuario = Usuario.new
			usuario.ci = usuario_params[:ci]
			usuario.password = usuario_params[:ci]
			usuario.nombres = usuario_params[:nombres]
			usuario.apellidos = usuario_params[:apellidos]
			
			hay_usuario = true if usuario.save
		end

		hay_usuario ? usuario : false

	end



	def self.separar_cadena cadena = nil
		if cadena.blank?
			return [nil,nil]
		else
			cadena = limpiar_cadena cadena
			a = cadena.split(" ")
			t = (a.count)-1
			i = (a.count/2)-1
			i = 0 if i < 0  

			return [a[0..i].join(" "),a[i+1..t].join(" ")]
		end
	end

	def self.limpiar_fila row
		row.field(0).delete! '^0-9'
		row.fields.each{|r| r = limpiar_cadena(r) if r}
		# row.field(1) = limpiar_cadena(row.field(1))
		# row.field(2) = limpiar_cadena row.field(2) if row.field(2)
		# row.field(3) = limpiar_cadena row.field(3) if row.field(3)
		# row.field(4) = limpiar_cadena row.field(4) if row.field(4)

		return row
	end

	def self.limpiar_cadena cadena
		cadena.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
		cadena.strip!
		return cadena
	end




end