module Admin
  class HorariosController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_administrador, except: [:get_bloques]
    before_action :set_horario, only: [:show, :edit, :update, :destroy]

    # GET /horarios
    # GET /horarios.json
    def index
      @horarios = Horario.all
    end

    def get_bloques
      @bloquesEditables = []
      if params[:asignatura]
        asig = Asignatura.find params[:id]

        secciones_ids = asig.secciones.where(periodo_id: current_periodo.id).ids
        @bloques = Bloquehorario.where(horario_id: secciones_ids).collect{|bh| {day: Bloquehorario.dias[bh.dia], periods: [["#{bh.entrada_to_schedule}", "#{bh.salida_to_schedule}"]], title: bh.descripcion_corta_para_asignaturas, color: bh.horario.color}}

      elsif params[:profesor]
        seccion = Seccion.find params[:id]
        profes_ids = seccion.todos_profes.ids
        if seccion.horario
          @bloquesEditables = Bloquehorario.where(horario_id: seccion.id).collect{|bh| {day: Bloquehorario.dias[bh.dia], periods: [["#{bh.entrada_to_schedule}", "#{bh.salida_to_schedule}"]], title: bh.horario.descripcion_seccion, color: bh.horario.color}} 
          @bloques = Bloquehorario.where(profesor_id: profes_ids).where("horario_id != #{seccion.id}").collect{|bh| {day: Bloquehorario.dias[bh.dia], periods: [["#{bh.entrada_to_schedule}", "#{bh.salida_to_schedule}"]], title: bh.descripcion_seccion_para_profesores, color: bh.horario.color}}
        else
          @bloques = Bloquehorario.where(profesor_id: profes_ids).collect{|bh| {day: Bloquehorario.dias[bh.dia], periods: [["#{bh.entrada_to_schedule}", "#{bh.salida_to_schedule}"]], title: bh.descripcion_seccion_para_profesores, color: bh.horario.color}}
        end


      elsif params[:estudiante]
        estu = Estudiante.find params[:id]
        secciones_ids = estu.secciones.where(periodo_id: current_periodo.id).ids 
        @bloques = Bloquehorario.where(horario_id: secciones_ids).collect{|bh| {day: Bloquehorario.dias[bh.dia], periods: [["#{bh.entrada_to_schedule}", "#{bh.salida_to_schedule}"]], title: bh.descripcion_seccion_para_profesores, color: bh.horario.color}}
      else
        @bloques = Bloquehorario.where(horario_id: params[:id]).collect{|bh| {day: Bloquehorario.dias[bh.dia], periods: [["#{bh.entrada_to_schedule}", "#{bh.salida_to_schedule}"]], title: bh.horario.descripcion_seccion, color: bh.horario.color} }
      end
      render json: {bloques: @bloques, bloquesEditables: @bloquesEditables}, status: :ok

    end

    # GET /horarios/1
    # GET /horarios/1.json
    def show
    end

    # GET /horarios/new
    def new
      @horario = Horario.new
      @seccion = Seccion.find params[:seccion_id]
      @horario.seccion_id = @seccion.id
      @titulo = 'Nuevo Horario'
      @profesores = @seccion.todos_profes

      profes_ids = @profesores.ids

      # @bloques = Bloquehorario.where(profesor_id: profes_ids).collect{|bh| {day: Bloquehorario.dias[bh.dia], periods: [["#{bh.entrada_to_schedule}", "#{bh.salida_to_schedule}"]]}}.to_json

      
      # bloques.each do |bh|
      #   if bh.dia and bh.entrada and bh.salida
      #     aux = {day: Bloquehorario.dias[bh.dia], periods: [["#{bh.entrada_to_schedule}", "#{bh.salida_to_schedule}"]]}
      #   end
        # aux = {day: 0, periods: [["00:00", "02:00"]]}
        # @aux = []

        # @aux = [{day: 0, periodos:[["01:00", "03:00"]]},
              # {day: 1, periodos:[["05:00", "07:00"]]}]
        # @aux = {"day": 0, periods: [["01:00", "03:00"]]}
        # @aux << {day: 1, periods: [["05:00", "07:00"]]}

        # @aux = [{day: 0, periods: [["01:00", "03:00"]]}, {day: 1, periods: [["02:00", "04:00"]]}

        # p aux.as_json
      # end


    end

    # GET /horarios/1/edit
    def edit
      @seccion = @horario.seccion
      @horario.seccion_id = @seccion.id
      @titulo = 'Editar Horario'
      @profesores = @seccion.todos_profes
    end

    # POST /horarios
    # POST /horarios.json
    def create

      @horario = Horario.new(horario_params)
      @seccion = Seccion.find params[:horario][:seccion_id]
      # @horario.color = "##{Random.new.bytes(3).unpack("H*")[0]}" # Colorizer.colorize_similarly(@horario.id.to_s, 0.35, 0.7)
      @horario.color = "rgba(#{rand(0..240)},#{rand(0..240)},#{rand(0..240)},0.3)"
      unless @horario.save
        flash[:error] = "No fue posible guardar el horario: #{@horario.errors.full_messages.to_sentence}"
        @seccion = @horario.seccion
        @titulo = 'Nuevo Horario'
        @profesores = @seccion.todos_profes
        render :new

      else
        flash[:success] = 'Horario generado con éxito'
        flash[:error] = ""
        create_bloquehorarios
        redirect_to asignatura_path(@seccion.asignatura.id)
      end

    end

    # PATCH/PUT /horarios/1
    # PATCH/PUT /horarios/1.json
    def update
      @horario.bloquehorarios.delete_all

      create_bloquehorarios

      redirect_to asignatura_path(@horario.seccion.asignatura.id)
    end

    # DELETE /horarios/1
    # DELETE /horarios/1.json
    def destroy
      asig_id = @horario.seccion.asignatura.id
      if @horario.destroy
        flash[:info] = 'Horario eliminado ccon éxito'
      else
        flash[:danger] = "Error al intentar eliminar el horario: #{@horario.errors.full_messages.to_sentence}"
      end
      redirect_to asignatura_path(asig_id)
    end

    private


      def create_bloquehorarios

        bloques = params[:bloques_ids]

        total = params[:bloquehorarios][:dias].length-1

        for i in(0..total) 
          profesor_id = params[:bloquehorarios][:profesores][i] if params[:bloquehorarios][:profesores]
          
          dia = params[:bloquehorarios][:dias][i]
          dia = Bloquehorario::DIAS[dia.to_i]

          horas = params[:bloquehorarios][:horas][i]
          entrada, salida = horas.split(' - ')

          @bloque = Bloquehorario.new
          @bloque.horario_id = @horario.id
          @bloque.dia = dia
          @bloque.entrada = Bloquehorario.format_time(entrada)
          @bloque.salida = Bloquehorario.format_time(salida)


          @bloque.profesor_id = profesor_id unless profesor_id.blank?

          # redirect_to bloquehorarios_path

          unless @bloque.save
            flash[:error] += @bloque.errors.full_messages.to_sentence
          end
        end
        flash[:error] = nil if flash[:error].blank?


      end
      # Use callbacks to share common setup or constraints between actions.
      def set_horario
        @horario = Horario.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def horario_params
        params.require(:horario).permit(:seccion_id, :titulo)
      end
  end
end