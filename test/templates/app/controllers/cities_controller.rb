class CitiesController < AjaxController

  self.nested = Country

  def show
    respond_to do |format|
      format.html { redirect_to_index flash.to_hash }
      format.json  { render :json => @entry }
    end
  end

end