require 'test_helper'
require 'action_pack'
require "action_controller"
require "action_controller/test_case"

class HelperTest < ActionController::TestCase

  # include Noffset::Helpers
  setup do
    @request = Rack::MockRequest.env_for("/", "HTTP_HOST" => "test.host", "REMOTE_ADDR" => "0.0.0.0", "HTTP_USER_AGENT" => "Rails Testing", )
  end
  
  schema do
    create_table "ding_bots", force: :cascade do |t|
      t.datetime :created_at
    end
  end

  class DingBot < ActiveRecord::Base
  end
  
  
  test 'helpers' do
    controller = ActionController::Base.new
    data = 10.times.map { DingBot.create! }.sort_by(&:id).sort_by(&:created_at).reverse
    
    controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots"))
    bots = DingBot.order(created_at: :desc, id: :asc).limit(3).paginate
    params = {after: {created_at: data[2].created_at, id: data[2].id}, order: {created_at: :desc, id: :asc}}
    assert_nil controller.prev_page_path(bots)
    assert_nil controller.prev_page_url(bots)
    assert_equal "/ding_bots?#{params.to_param}", controller.next_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{params.to_param}", controller.next_page_url(bots)

    controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots?#{params.to_param}"))
    bots = DingBot.order(created_at: :desc, id: :asc).limit(3).paginate(after: {created_at: data[2].created_at, id: data[2].id})
    prev_params = {before: {created_at: data[3].created_at, id: data[3].id}, order: {created_at: :desc, id: :asc}}
    params = {after: {created_at: data[5].created_at, id: data[5].id}, order: {created_at: :desc, id: :asc}}
    assert_equal "/ding_bots?#{prev_params.to_param}", controller.prev_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{prev_params.to_param}", controller.prev_page_url(bots)
    assert_equal "/ding_bots?#{params.to_param}", controller.next_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{params.to_param}", controller.next_page_url(bots)
    
    controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots?#{params.to_param}"))
    bots = DingBot.order(created_at: :desc, id: :asc).limit(3).paginate(after: {created_at: data[5].created_at, id: data[5].id})
    prev_params = {before: {created_at: data[6].created_at, id: data[6].id}, order: {created_at: :desc, id: :asc}}
    params = {after: {created_at: data[8].created_at, id: data[8].id}, order: {created_at: :desc, id: :asc}}
    assert_equal "/ding_bots?#{prev_params.to_param}", controller.prev_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{prev_params.to_param}", controller.prev_page_url(bots)
    assert_equal "/ding_bots?#{params.to_param}", controller.next_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{params.to_param}", controller.next_page_url(bots)
    
    controller.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://example.org/ding_bots?#{params.to_param}"))
    bots = DingBot.order(created_at: :desc, id: :asc).limit(3).paginate(after: {created_at: data[8].created_at, id: data[8].id})
    prev_params = {before: {created_at: data[9].created_at, id: data[9].id}, order: {created_at: :desc, id: :asc}}
    params = {after: {created_at: data[9].created_at, id: data[9].id}, order: {created_at: :desc, id: :asc}}
    assert_equal "/ding_bots?#{prev_params.to_param}", controller.prev_page_path(bots)
    assert_equal "http://example.org/ding_bots?#{prev_params.to_param}", controller.prev_page_url(bots)
    assert_nil controller.next_page_path(bots)
    assert_nil controller.next_page_url(bots)
  end

end