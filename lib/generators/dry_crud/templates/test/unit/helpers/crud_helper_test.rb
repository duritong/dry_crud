require 'test_helper'
require 'crud_test_model'

class CrudHelperTest < ActionView::TestCase
  
  include StandardHelper
  include CrudTestHelper
  
  setup :reset_db, :setup_db, :create_test_data
  teardown :reset_db
  
  test "standard crud table" do
    @entries = CrudTestModel.all
    
    t = with_test_routing do 
      crud_table
    end
    
    assert_match /(<tr.+?<\/tr>){7}/m, t
    assert_match /(<th><a .*asc.*>.*<\/a><\/th>){4}/m, t
    assert_match /(<td><a href.+?<\/a><\/td>.*?){18}/m, t  # show, edit, delete links
  end
  
  test "custom crud table with attributes" do
    @entries = CrudTestModel.all
    
    t = with_test_routing do
      crud_table :name, :children, :companion_id
    end
        
    assert_match /(<tr.+?<\/tr>){7}/m, t
    assert_match /(<th.+?<\/th>){4}/m, t
    assert_match /(<td><a href.+?<\/a><\/td>.*?){18}/m, t  # show, edit, delete links
  end
    
  test "custom crud table with block" do
    @entries = CrudTestModel.all
    
    t = with_test_routing do
      crud_table do |t|
        t.attrs :name, :children, :companion_id
        t.col("head") {|e| content_tag :span, e.income.to_s }
      end
    end
    
    assert_match /(<tr.+?<\/tr>){7}/m, t
    assert_match /(<th.+?<\/th>){4}/m, t
    assert_match /(<span>.+?<\/span>.*?){6}/m, t
    assert_no_match /(<td><a href.+?<\/a><\/td>.*?)/m, t
  end
  
  test "custom crud table with attributes and block" do
    @entries = CrudTestModel.all
    
    t = with_test_routing do
      crud_table :name, :children, :companion_id do |t|
        t.col("head") {|e| content_tag :span, e.income.to_s }
      end
    end
    
    assert_match /(<tr.+?<\/tr>){7}/m, t
    assert_match /(<th.+?<\/th>){4}/m, t
    assert_match /(<span>.+?<\/span>.*?){6}/m, t
    assert_no_match /(<td><a href.+?<\/a><\/td>.*?)/m, t
  end
    
  test "standard crud table with ascending sort params" do
    def params
      {:sort => 'children', :sort_dir => 'asc'}
    end
  
    @entries = CrudTestModel.all
    
    t = with_test_routing do 
      crud_table
    end
    
    assert_match /(<tr.+?<\/tr>){7}/m, t
    assert_match /(<th><a .*desc.*>Children<\/a> &darr;<\/th>){1}/m, t
    assert_match /(<th><a .*asc.*>.*<\/a><\/th>){3}/m, t
    assert_match /(<td><a href.+?<\/a><\/td>.*?){18}/m, t
  end
  
  test "standard crud table with descending sort params" do
    def params
      {:sort => 'children', :sort_dir => 'desc'}
    end
  
    @entries = CrudTestModel.all
    
    t = with_test_routing do 
      crud_table
    end
    
    assert_match /(<tr.+?<\/tr>){7}/m, t
    assert_match /(<th><a .*asc.*>Children<\/a> &uarr;<\/th>){1}/m, t
    assert_match /(<th><a .*asc.*>.*<\/a><\/th>){4}/m, t
    assert_match /(<td><a href.+?<\/a><\/td>.*?){18}/m, t
  end
    
  test "crud table with custom column sort params" do
    def params
      {:sort => 'chatty', :sort_dir => 'asc'}
    end
  
    @entries = CrudTestModel.all
    
    t = with_test_routing do 
      crud_table :name, :children, :chatty
    end
    
    assert_match /(<tr.+?<\/tr>){7}/m, t
    assert_match /(<th><a .*desc.*>Chatty<\/a> &darr;<\/th>){1}/m, t
    assert_match /(<th><a .*asc.*>.*<\/a><\/th>){2}/m, t
    assert_match /(<td><a href.+?<\/a><\/td>.*?){18}/m, t
  end
  
  test "crud form" do
    @entry = CrudTestModel.first
    f = with_test_routing do
      capture { crud_form }
    end
    
    assert_match /form .*?action="\/crud_test_models\/#{@entry.id}"/, f
    assert_match /input .*?name="crud_test_model\[name\]" .*?type="text"/, f
    assert_match /input .*?name="crud_test_model\[whatever\]" .*?type="text"/, f
    assert_match /input .*?name="crud_test_model\[children\]" .*?type="text"/, f
    assert_match /input .*?name="crud_test_model\[rating\]" .*?type="text"/, f
    assert_match /input .*?name="crud_test_model\[income\]" .*?type="text"/, f
    assert_match /select .*?name="crud_test_model\[birthdate\(1i\)\]"/, f
    assert_match /input .*?name="crud_test_model\[human\]" .*?type="checkbox"/, f
    assert_match /select .*?name="crud_test_model\[companion_id\]"/, f
    assert_match /textarea .*?name="crud_test_model\[remarks\]"/, f
  end
  
  test "default attributes do not include id" do 
    assert_equal [:name, :whatever, :children, :companion_id, :rating, :income, 
                  :birthdate, :human, :remarks, :created_at, :updated_at], default_attrs
  end
  
  # Controller helper methods for the tests
  
  def model_class
    CrudTestModel
  end
  
  def params
  	{}
  end
  
  def sortable?(attr)
  	true
  end

    
  private
  
  def with_test_routing
    with_routing do |set|
      set.draw { resources :crud_test_models }
      # used to define a controller in these tests
      set.default_url_options = {:controller => 'crud_test_models'}
      yield
    end
  end
end
