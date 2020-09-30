module Admin
  class PerfilesController < ApplicationController
    before_action :filtro_super_admin!
    before_action :set_perfil, only: [:show, :edit, :update, :destroy]

    # GET /perfiles
    # GET /perfiles.json

    # def autorizar_usuario
    #   perfil = Perfil.find params[:id]
    #   usuario = Usuario.find(params[:usuario_id])
    #   perfil_restringidas_ids = perfil.restringidas.ids

    #   autorizadas_ids = usuario.autorizadas.where("restringida_id NOT IN (#{perfil_restringidas_ids.flatten.join(',')})").ids
    #   Autorizada.where(id: autorizadas_ids).delete_all #if autorizadas_ids.any?

    #   autorizadas_ids = perfil_restringidas_ids - usuario.autorizadas.ids
    #   Autorizada.create(autorizadas_ids.map{|id| {restringida_id: id, usuario_id: params[:usuario_id]}}) if autorizadas_ids.any?
    #   render json: 'Autorizado Perfil', status: :ok
    # end

    def autorizar_usuario
      perfil = Perfil.find params[:id]
      usuario = Usuario.find(params[:usuario_id])
      usuario.administrador.update(perfil_id: perfil.id) if usuario.administrador
      restringidas_ids = perfil.restringidas.ids
      autorizadas_ids = usuario.autorizadas.ids
      Autorizada.where(id: autorizadas_ids).delete_all if autorizadas_ids.any?
      Autorizada.create(restringidas_ids.map{|id| {restringida_id: id, usuario_id: params[:usuario_id]}}) if restringidas_ids.any?
      render json: 'Autorizado Perfil', status: :ok
    end

    def index
      @perfiles = Perfil.all
    end

    # GET /perfiles/1
    # GET /perfiles/1.json
    def show
    end

    # GET /perfiles/new
    def new
      @perfil = Perfil.new
    end

    # GET /perfiles/1/edit
    def edit
    end

    # POST /perfiles
    # POST /perfiles.json
    def create
      @perfil = Perfil.new(perfil_params)

      respond_to do |format|
        if @perfil.save
          if params[:usuario_id]
            @usuario = Usuario.find params[:usuario_id]
            @usuario.administrador.update(perfil_id: @perfil.id) if @usuario.administrador
            @usuario.restringidas.each do |rest|
              PerfilRestringida.create(restringida_id: rest.id, perfil_id: @perfil.id)
            end

          end
          format.html { redirect_back fallback_location: usuario_path(@usuario), notice: 'Perfil creado con éxito' }
          format.json { render json: {perfiles: Perfil.all, msg: 'Perfil agregado con éxito'}, status: :unprocessable_entity }
        else
          format.html { redirect_back fallback_location: usuario_path(@usuario), notice: "Error el intentar crear el perfil: #{@perfil.errors.full_messages.to_sentence}"}
          format.json { render json: @perfil.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /perfiles/1
    # PATCH/PUT /perfiles/1.json
    def update
      respond_to do |format|
        if @perfil.update(perfil_params)
          format.html { redirect_back fallback_location: usuario_path(params[:usuario_id]), notice: 'Perfil actualizado con éxito' }
          format.json { render :show, status: :ok, location: @perfil }
        else
          format.html { redirect_back fallback_location: usuario_path(params[:usuario_id]), notice: "Error el intentar crear el perfil: #{@perfil.errors.full_messages.to_sentence}" }
          format.json { render json: @perfil.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /perfiles/1
    # DELETE /perfiles/1.json
    def destroy
      @perfil.destroy
      respond_to do |format|
        format.html { redirect_back fallback_location: usuario_path(params[:usuario_id]), notice: 'Perfil eliminado'}
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_perfil
        @perfil = Perfil.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def perfil_params
        params.require(:perfil).permit(:nombre)
      end
  end
end