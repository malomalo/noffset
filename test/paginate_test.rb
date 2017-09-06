require 'test_helper'

class PaginateTest < ActiveSupport::TestCase

  schema do
    create_table "ding_bots", force: :cascade do |t|
      t.datetime :created_at
    end
  end

  class DingBot < ActiveRecord::Base
  end
  
  def teardown
    DingBot.delete_all
  end

  test '#next_page? with .paginate' do
    bots = DingBot.order(id: :asc).limit(2).paginate
    assert_equal false, bots.next_page?

    10.times.map { DingBot.create! }.map(&:id).sort

    assert_equal true, bots.reload.next_page?
  end

  test '#next_page? with .paginate(after: )' do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort

    bots = DingBot.order(id: :asc).limit(2).paginate
    assert_equal true, bots.next_page?

    bots = DingBot.order(id: :asc).limit(2).paginate(after: {id: ids[3]})
    assert_equal true, bots.next_page?

    bots = DingBot.order(id: :asc).limit(2).paginate(after: {id: ids[7]})
    assert_equal false, bots.next_page?
  end

  test '#next_page? with .paginate(before: )' do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort

    bots = DingBot.order(id: :asc).limit(2).paginate(before: {id: ids[8]})
    assert_equal true, bots.next_page?

    bots = DingBot.order(id: :asc).limit(2).paginate(before: {id: ids[5]})
    assert_equal true, bots.next_page?

    bots = DingBot.order(id: :asc).limit(2).paginate(before: {id: ids[2]})
    assert_equal true, bots.next_page?
  end

  test '#prev_page? with .paginate' do
    bots = DingBot.order(id: :asc).limit(2).paginate
    assert_equal false, bots.prev_page?

    10.times.map { DingBot.create! }.map(&:id).sort

    assert_equal false, bots.reload.prev_page?
  end

  test '#prev_page? with .paginate(after: )' do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort

    bots = DingBot.order(id: :asc).limit(2).paginate
    assert_equal false, bots.prev_page?

    bots = DingBot.order(id: :asc).limit(2).paginate(after: {id: ids[3]})
    assert_equal true, bots.prev_page?

    bots = DingBot.order(id: :asc).limit(2).paginate(after: {id: ids[7]})
    assert_equal true, bots.prev_page?
  end

  test '#prev_page? with .paginate(before: )' do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort

    bots = DingBot.order(id: :asc).limit(2).paginate(before: {id: ids[8]})
    assert_equal true, bots.prev_page?

    bots = DingBot.order(id: :asc).limit(2).paginate(before: {id: ids[5]})
    assert_equal true, bots.prev_page?

    bots = DingBot.order(id: :asc).limit(2).paginate(before: {id: ids[2]})
    assert_equal false, bots.prev_page?
  end

  test "paginating forward through all records" do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort

    bots = DingBot.order(id: :asc).limit(2).paginate
    while bots.next_page?
      bots.each { |bot| ids.shift if ids.first == bot.id }
      bots = DingBot.order(id: :asc).limit(2).paginate(bots.next_params)
    end
    bots.each { |bot| ids.shift if ids.first == bot.id }
    bots = DingBot.order(id: :asc).limit(2).paginate(bots.next_params)

    assert ids.empty?
    assert bots.prev_page?
    assert !bots.next_page?
  end

  test "paginating backward through all records" do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort

    bots = DingBot.order(id: :asc).limit(2).paginate(after: {id: ids[7]})
    while bots.prev_page?
      bots.reverse.each { |bot| ids.pop if ids.last == bot.id }
      bots = DingBot.order(id: :asc).limit(2).paginate(bots.prev_params)
    end
    bots.reverse.each { |bot| ids.pop if ids.last == bot.id }
    bots = DingBot.order(id: :asc).limit(2).paginate(bots.prev_params)

    assert ids.empty?
    assert !bots.prev_page?
    assert bots.next_page?
  end

  test "::paginate(after: {id: N}, order: {id: :desc})" do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort.reverse

    bots = DingBot.order(id: :desc).paginate(after: {id: ids[4]}).limit(2)
    assert_equal(<<-SQL.strip.gsub(/\s+/, ' '), bots.to_sql.strip.gsub(/\s+/, ' ').gsub('"', ''))
      SELECT ding_bots.* FROM ding_bots
      WHERE (ding_bots.id < #{ids[4]})
      ORDER BY ding_bots.id DESC
      LIMIT 3
    SQL

    assert_equal ids[5..6], bots.records.map(&:id)
    assert bots.prev_page?
    assert bots.next_page?
    assert_equal({before: {id: ids[5]}, order: {id: :desc}}, bots.prev_params)
    assert_equal({after: {id: ids[6]}, order: {id: :desc}}, bots.next_params)
  end

  test "::paginate(before: {id: N}, order: {id: :desc})" do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort.reverse

    bots = DingBot.paginate(before: {id: ids[4]}).limit(2).order(id: :desc)
    assert_equal(<<-SQL.strip.gsub(/\s+/, ' '), bots.to_sql.strip.gsub(/\s+/, ' ').gsub('"', ''))
      SELECT ding_bots.* FROM ding_bots
      WHERE (ding_bots.id > #{ids[4]})
      ORDER BY ding_bots.id ASC
      LIMIT 3
    SQL

    assert_equal ids[2..3], bots.records.map(&:id)
    assert bots.prev_page?
    assert bots.next_page?
    assert_equal({before: {id: ids[2]}, order: {id: :desc}}, bots.prev_params)
    assert_equal({after: {id: ids[3]}, order: {id: :desc}}, bots.next_params)
  end



  test "::paginate(after: {id: N}, order: {id: :asc})" do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort

    bots = DingBot.paginate(after: {id: ids[4]}).limit(2).order(id: :asc)
    assert_equal(<<-SQL.strip.gsub(/\s+/, ' '), bots.to_sql.strip.gsub(/\s+/, ' ').gsub('"', ''))
      SELECT ding_bots.*
      FROM ding_bots
      WHERE (ding_bots.id > #{ids[4]})
      ORDER BY ding_bots.id ASC
      LIMIT 3
    SQL

    assert_equal ids[5..6], bots.records.map(&:id)
    assert bots.prev_page?
    assert bots.next_page?
    assert_equal({before: {id: ids[5]}, order: {id: :asc}}, bots.prev_params)
    assert_equal({after: {id: ids[6]}, order: {id: :asc}}, bots.next_params)
  end

  test "::paginate(before: {id: N}, order: {id: :asc})" do
    ids = 10.times.map { DingBot.create! }.map(&:id).sort

    bots = DingBot.paginate(before: {id: ids[4]}).limit(2).order(id: :asc)
    assert_equal(<<-SQL.strip.gsub(/\s+/, ' '), bots.to_sql.strip.gsub(/\s+/, ' ').gsub('"', ''))
      SELECT ding_bots.*
      FROM ding_bots
      WHERE (ding_bots.id < #{ids[4]})
      ORDER BY ding_bots.id DESC
      LIMIT 3
    SQL

    assert_equal ids[2..3], bots.records.map(&:id)
    assert bots.prev_page?
    assert bots.next_page?
    assert_equal({before: {id: ids[2]}, order: {id: :asc}}, bots.prev_params)
    assert_equal({after: {id: ids[3]}, order: {id: :asc}}, bots.next_params)
  end



  test "::paginate(after: {id: N}, order: {created_at: :asc, id: :desc})" do
    data = 10.times.map { DingBot.create! }.sort_by(&:id).reverse.sort_by(&:created_at)

    bots = DingBot.paginate(after: {created_at: data[4].created_at, id: data[4].id}).limit(2).order(created_at: :asc, id: :desc)
    assert_equal(<<-SQL.strip.gsub(/\s+/, ' '), bots.to_sql.strip.gsub(/\s+/, ' ').gsub('"', ''))
      SELECT ding_bots.*
      FROM ding_bots
      WHERE ((ding_bots.created_at > '#{data[4].created_at.iso8601(6).gsub('T', ' ').gsub('Z', '')}') OR (ding_bots.created_at = '#{data[4].created_at.iso8601(6).gsub('T', ' ').gsub('Z', '')}' AND ding_bots.id < #{data[4].id}))
      ORDER BY ding_bots.created_at ASC, ding_bots.id DESC
      LIMIT 3
    SQL

    assert_equal data[5..6].map(&:id), bots.records.map(&:id)
    assert bots.prev_page?
    assert bots.next_page?
    assert_equal({before: {created_at: data[5].created_at, id: data[5].id}, order: {created_at: :asc, id: :desc}}, bots.prev_params)
    assert_equal({after: {created_at: data[6].created_at, id: data[6].id}, order: {created_at: :asc, id: :desc}}, bots.next_params)
  end

  test "::paginate(before: {id: N}, order: {created_at: :asc, id: :desc})" do
    data = 10.times.map { DingBot.create! }.sort_by(&:id).reverse.sort_by(&:created_at)

    bots = DingBot.paginate(before: {created_at: data[4].created_at, id: data[4].id}).limit(2).order(created_at: :asc, id: :desc)
    assert_equal(<<-SQL.strip.gsub(/\s+/, ' '), bots.to_sql.strip.gsub(/\s+/, ' ').gsub('"', ''))
      SELECT ding_bots.*
      FROM ding_bots
      WHERE ((ding_bots.created_at < '#{data[4].created_at.iso8601(6).gsub('T', ' ').gsub('Z', '')}') OR (ding_bots.created_at = '#{data[4].created_at.iso8601(6).gsub('T', ' ').gsub('Z', '')}' AND ding_bots.id > #{data[4].id}))
      ORDER BY ding_bots.created_at DESC, ding_bots.id ASC
      LIMIT 3
    SQL

    assert_equal data[2..3].map(&:id), bots.records.map(&:id)
    assert bots.prev_page?
    assert bots.next_page?
    assert_equal({before: {created_at: data[2].created_at, id: data[2].id}, order: {created_at: :asc, id: :desc}}, bots.prev_params)
    assert_equal({after: {created_at: data[3].created_at, id: data[3].id}, order: {created_at: :asc, id: :desc}}, bots.next_params)
  end



  test "::paginate(after: {id: N}, order: {created_at: :desc, id: :asc})" do
    data = 10.times.map { DingBot.create! }.sort_by(&:id).sort_by(&:created_at).reverse

    bots = DingBot.paginate(after: {created_at: data[4].created_at, id: data[4].id}).limit(2).order(created_at: :desc, id: :asc)
    assert_equal(<<-SQL.strip.gsub(/\s+/, ' '), bots.to_sql.strip.gsub(/\s+/, ' ').gsub('"', ''))
      SELECT ding_bots.*
      FROM ding_bots
      WHERE ((ding_bots.created_at < '#{data[4].created_at.iso8601(6).gsub('T', ' ').gsub('Z', '')}') OR (ding_bots.created_at = '#{data[4].created_at.iso8601(6).gsub('T', ' ').gsub('Z', '')}' AND ding_bots.id > #{data[4].id}))
      ORDER BY ding_bots.created_at DESC, ding_bots.id ASC
      LIMIT 3
    SQL

    assert_equal data[5..6].map(&:id), bots.records.map(&:id)
    assert bots.prev_page?
    assert bots.next_page?
    assert_equal({before: {created_at: data[5].created_at, id: data[5].id}, order: {created_at: :desc, id: :asc}}, bots.prev_params)
    assert_equal({after: {created_at: data[6].created_at, id: data[6].id}, order: {created_at: :desc, id: :asc}}, bots.next_params)
  end

  test "::paginate(before: {id: N}, order: {created_at: :desc, id: :asc})" do
    data = 10.times.map { DingBot.create! }.sort_by(&:id).reverse.sort_by(&:created_at).reverse

    bots = DingBot.paginate(before: {created_at: data[4].created_at, id: data[4].id}).limit(2).order(created_at: :desc, id: :asc)
    assert_equal(<<-SQL.strip.gsub(/\s+/, ' '), bots.to_sql.strip.gsub(/\s+/, ' ').gsub('"', ''))
      SELECT ding_bots.*
      FROM ding_bots
      WHERE ((ding_bots.created_at > '#{data[4].created_at.iso8601(6).gsub('T', ' ').gsub('Z', '')}') OR (ding_bots.created_at = '#{data[4].created_at.iso8601(6).gsub('T', ' ').gsub('Z', '')}' AND ding_bots.id < #{data[4].id}))
      ORDER BY ding_bots.created_at ASC, ding_bots.id DESC
      LIMIT 3
    SQL

    assert_equal data[2..3].map(&:id), bots.records.map(&:id)
    assert bots.prev_page?
    assert bots.next_page?
    assert_equal({before: {created_at: data[2].created_at, id: data[2].id}, order: {created_at: :desc, id: :asc}}, bots.prev_params)
    assert_equal({after: {created_at: data[3].created_at, id: data[3].id}, order: {created_at: :desc, id: :asc}}, bots.next_params)
  end
  
end