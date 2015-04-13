require 'spec_helper'

describe Rystrix::Bucket do
  describe '#increment' do
    context 'with same status' do
      it 'should be increased' do
        bucket = Rystrix::Bucket.new(size: 10, par: 1)
        bucket.increment :success
        bucket.increment :success
        bucket.increment :success
        expect(bucket.current.success).to eq(3)
      end
    end

    context 'across statuses' do
      it 'should be ok' do
        bucket = Rystrix::Bucket.new(size: 10, par: 0.01)
        bucket.increment :success
        sleep 0.01
        bucket.increment :success
        expect(bucket.current.success).to eq(1)
      end
    end
  end

  describe '#total' do
    context 'with no limit exceeded' do
      it 'should be ok' do
        size = 10
        par = 0.05
        bucket = Rystrix::Bucket.new(size: size, par: par)
        size.times do |n|
          bucket.increment :success
          sleep par if n != size - 1
        end
        expect(bucket.total.success).to eq(size)
      end
    end

    context 'with limit exceeded' do
      it 'should be ok' do
        size = 10
        par = 0.01
        bucket = Rystrix::Bucket.new(size: size, par: par)
        100.times do
          bucket.increment :success
        end
        sleep par * size
        expect(bucket.total.success).to eq(0)
      end
    end
  end
end
