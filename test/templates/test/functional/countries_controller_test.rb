require 'test_helper'
require File.join('functional', 'crud_controller_test_helper')

class CountriesControllerTest < ActionController::TestCase

  include CrudControllerTestHelper

  def test_setup
    assert_equal 3, Country.count
    assert_recognizes({:controller => 'countries', :action => 'index'}, 'countries')
    assert_recognizes({:controller => 'countries', :action => 'show', :id => '1'}, 'countries/1')
  end

  def test_index
    super
    assert_equal Country.order('name').all, assigns(:entries)
  end

  def test_show
    get :show, test_params(:id => test_entry.id)
    assert_redirected_to_index
  end

  protected

  def test_entry
    countries(:usa)
  end

  def test_entry_attrs
    {:name => 'United States of America', :code => 'US'}
  end

end
