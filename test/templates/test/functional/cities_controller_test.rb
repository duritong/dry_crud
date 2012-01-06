require 'test_helper'
require File.join('functional', 'crud_controller_test_helper')

class CitiesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  def test_setup
    assert_equal 3, City.count
    assert_recognizes({:controller => 'cities', :action => 'index', :country_id => '1'}, 'countries/1/cities')
    assert_recognizes({:controller => 'cities', :action => 'show', :country_id => '2', :id => '1'}, 'countries/2/cities/1')
  end

  def test_index
    super
    assert_equal 1, assigns(:entries).size
    assert_equal test_entry.country.cities.order('countries.code, cities.name'), assigns(:entries)
  end

  def test_show
    get :show, test_params(:id => test_entry.id)
    assert_redirected_to_index
  end

  def test_destroy_with_inhabitants
    ny = cities(:ny)
    assert_no_difference('City.count') do
      request.env["HTTP_REFERER"]
      delete :destroy, :country_id => ny.country_id, :id => ny.id
    end
    assert_redirected_to :action => 'show'
    assert flash.alert
  end

  protected

  def test_entry
    cities(:rj)
  end

  def test_entry_attrs
    {:name => 'Rejkiavik'}
  end

end
