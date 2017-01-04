require 'rspec'
require 'json'
require_relative '../src/request.rb'

module Secrets
  EXPECTED_APP_ID = 'blah'
end

describe Request do
  describe 'valid?' do
    it 'should mark empty request bodies as invalid' do
      expect(Request.extract_from_request_body('').valid?).to be(false)
    end

    it 'should mark unexpected app ids as invalid' do
      body = JSON.generate({
        session: { application: { applicationId: 'invalid' } },
        request: { type: 'AudioPlayer.ABC' }
      })
      expect(Request.extract_from_request_body(body).valid?).to be(false)
    end

    it 'should mark expected app ids as valid' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' } },
        request: { type: 'AudioPlayer.ABC' }
      })
      expect(Request.extract_from_request_body(body).valid?).to be(true)
    end

    it 'should mark an invalid request_type as invalid' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' } },
        request: { type: 'YoIdk' }
      })
      expect(Request.extract_from_request_body(body).valid?).to be(false)
    end
  end

  describe 'request_type' do
    it 'should use any AudioPlayer request as the request type' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' } },
        request: { type: 'AudioPlayer.ABC' }
      })
      expect(Request.extract_from_request_body(body).request_type).to eq('AudioPlayer.ABC')
    end

    it 'should use any the intent name for any intent request as the request type' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' } },
        request: { type: 'IntentRequest', intent: { name: 'IntentName' } }
      })
      expect(Request.extract_from_request_body(body).request_type).to eq('IntentName')
    end

    it 'should use nil as the request type for unexpected cases' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' } },
        request: { type: 'YoIdk' }
      })
      expect(Request.extract_from_request_body(body).request_type).to be(nil)
    end
  end
end
