require 'test_helper'
require 'action_pack'
require "action_controller"
require "action_controller/test_case"

class HelperTest < ActionController::TestCase

  setup do
    @controller = ActionController::Base.new
    DingBot.delete_all
    @data = 10.times.map { DingBot.create! }.sort_by(&:id).sort_by(&:created_at).reverse
    @request = Rack::MockRequest.env_for("/", "HTTP_HOST" => "test.host", "REMOTE_ADDR" => "0.0.0.0", "HTTP_USER_AGENT" => "Rails Testing")
  end

  schema do
    create_table "ding_bots", force: :cascade do |t|
      t.datetime :created_at
    end
  end

  class DingBot < ActiveRecord::Base
  end

  test 'helpers on first page' do
    @controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots"))
    bots = DingBot.order(created_at: :desc, id: :asc).limit(3).paginate
    
    assert_nil @controller.first_page_path(bots)
    assert_nil @controller.first_page_url(bots)

    assert_nil @controller.prev_page_path(bots)
    assert_nil @controller.prev_page_url(bots)

    next_params = {after: {created_at: @data[2].created_at, id: @data[2].id}, order: {created_at: :desc, id: :asc}}
    assert_equal "/ding_bots?#{next_params.to_param}", @controller.next_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{next_params.to_param}", @controller.next_page_url(bots)

    last_params = {last: true}
    assert_equal "/ding_bots?#{last_params.to_param}", @controller.last_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{last_params.to_param}", @controller.last_page_url(bots)
  end

  test 'helpers on second page' do
    params = {after: {created_at: @data[2].created_at, id: @data[2].id}, order: {created_at: :desc, id: :asc}}
    @controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots?#{params.to_param}"))
    bots = DingBot.order(params[:order]).limit(3).paginate(params.slice(:before, :after, :last))
    
    first_params = params.except(:after, :before, :last)
    assert_equal "/ding_bots?#{first_params.to_param}", @controller.first_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{first_params.to_param}", @controller.first_page_url(bots)

    prev_params = params.except(:before, :after, :last).merge({before: {created_at: @data[3].created_at, id: @data[3].id}})
    assert_equal "/ding_bots?#{prev_params.to_param}", @controller.prev_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{prev_params.to_param}", @controller.prev_page_url(bots)
    
    next_params = params.except(:before, :after, :last).merge({after: {created_at: @data[5].created_at, id: @data[5].id}})
    assert_equal "/ding_bots?#{next_params.to_param}", @controller.next_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{next_params.to_param}", @controller.next_page_url(bots)

    last_params = params.except(:before, :after, :last).merge({last: true})
    assert_equal "/ding_bots?#{last_params.to_param}", @controller.last_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{last_params.to_param}", @controller.last_page_url(bots)
  end

  test 'helpers on third page' do
    params = {after: {created_at: @data[5].created_at, id: @data[5].id}, order: {created_at: :desc, id: :asc}}
    @controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots?#{params.to_param}"))
    bots = DingBot.order(params[:order]).limit(3).paginate(params.slice(:before, :after, :last))
    
    first_params = params.except(:after, :before, :last)
    assert_equal "/ding_bots?#{first_params.to_param}", @controller.first_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{first_params.to_param}", @controller.first_page_url(bots)

    prev_params = params.except(:before, :after, :last).merge({before: {created_at: @data[6].created_at, id: @data[6].id}})
    assert_equal "/ding_bots?#{prev_params.to_param}", @controller.prev_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{prev_params.to_param}", @controller.prev_page_url(bots)
    
    next_params = params.except(:before, :after, :last).merge({after: {created_at: @data[8].created_at, id: @data[8].id}})
    assert_equal "/ding_bots?#{next_params.to_param}", @controller.next_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{next_params.to_param}", @controller.next_page_url(bots)

    last_params = params.except(:before, :after, :last).merge({last: true})
    assert_equal "/ding_bots?#{last_params.to_param}", @controller.last_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{last_params.to_param}", @controller.last_page_url(bots)
  end

  test 'helpers on fourth and last page using after' do
    params = {after: {created_at: @data[8].created_at, id: @data[8].id}, order: {created_at: :desc, id: :asc}}
    @controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots?#{params.to_param}"))
    bots = DingBot.order(params[:order]).limit(3).paginate(params.slice(:before, :after, :last))
    
    first_params = params.except(:after, :before, :last)
    assert_equal "/ding_bots?#{first_params.to_param}", @controller.first_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{first_params.to_param}", @controller.first_page_url(bots)

    prev_params = params.except(:before, :after, :last).merge({before: {created_at: @data[9].created_at, id: @data[9].id}})
    assert_equal "/ding_bots?#{prev_params.to_param}", @controller.prev_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{prev_params.to_param}", @controller.prev_page_url(bots)
    
    puts bots.last_page?
    puts  bots.map(&:id)
    assert_nil @controller.next_page_path(bots)
    assert_nil @controller.next_page_url(bots)

    assert_nil @controller.last_page_path(bots)
    assert_nil @controller.last_page_url(bots)
  end

  test 'helpers on fourth and last page using last' do
    params = {last: true, order: {created_at: :desc, id: :asc}}
    @controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots?#{params.to_param}"))
    bots = DingBot.order(params[:order]).limit(3).paginate(params.slice(:before, :after, :last))
    
    first_params = params.except(:after, :before, :last)
    assert_equal "/ding_bots?#{first_params.to_param}", @controller.first_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{first_params.to_param}", @controller.first_page_url(bots)

    prev_params = params.except(:before, :after, :last).merge({before: {created_at: @data[7].created_at, id: @data[7].id}})
    assert_equal "/ding_bots?#{prev_params.to_param}", @controller.prev_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{prev_params.to_param}", @controller.prev_page_url(bots)
    
    puts bots.last_page?
    puts  bots.map(&:id)
    assert_nil @controller.next_page_path(bots)
    assert_nil @controller.next_page_url(bots)

    assert_nil @controller.last_page_path(bots)
    assert_nil @controller.last_page_url(bots)
  end

end