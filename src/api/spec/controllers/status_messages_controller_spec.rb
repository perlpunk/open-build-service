require 'rails_helper'

RSpec.describe StatusMessagesController do
  render_views

  let(:user) { create(:confirmed_user) }
  let(:status_message) { create(:status_message, user: user) }

  before do
    login user
  end

  describe 'GET #show' do
    before { status_message }

    subject! { get :show, params: { id: status_message.id }, format: :xml }

    it { is_expected.to have_http_status(:success) }

    it 'returns the requested status message' do
      assert_select 'status_message' do
        assert_select 'message', status_message.message
      end
    end
  end

  describe 'GET #index' do
    let!(:status_messages) { create_list(:status_message, 3) }

    subject! { get :index, format: :xml }

    it { is_expected.to have_http_status(:success) }

    it 'returns all status messages' do
      assert_select 'status_messages[count=3]' do
        status_messages.each do |status_message|
          assert_select 'message', status_message.message
        end
      end
    end
  end

  describe '#create' do
    let(:request_xml) do
      <<~XML
        <status_message>
          <message>New message was sent!</message>
          <severity>green</severity>
          <scope>all_users</scope>
        </status_message>
      XML
    end

    context 'when user is not admin' do
      subject! { post :create, body: request_xml, format: :xml }

      it { is_expected.to have_http_status(:forbidden) }
    end

    context 'when requester is admin' do
      let(:admin) { create(:admin_user) }

      before do
        login admin
      end

      subject! { post :create, body: request_xml, format: :xml }

      it { is_expected.to have_http_status(:success) }

      it { expect(StatusMessage.last.message).to eq('New message was sent!') }
    end

    context 'create with a wrong XML' do
      let(:request_xml) do
        <<~XML
          <stadus_message>
            <message>New message was sent!</message>
            <severity>information</severity>
          </status_message>
        XML
      end
      let(:admin) { create(:admin_user) }

      before do
        login admin
      end

      subject! { post :create, body: request_xml, format: :xml }

      it { is_expected.to have_http_status(:bad_request) }
    end
  end

  describe '#destroy' do
    context 'when user is not admin' do
      subject! { delete :destroy, params: { id: status_message.id }, format: :xml }

      it { is_expected.to have_http_status(:forbidden) }
      it { expect(status_message.deleted_at).to be_nil }
    end

    context 'when requester is admin' do
      let(:admin) { create(:admin_user) }

      before do
        login admin
      end

      subject! { delete :destroy, params: { id: status_message.id }, format: :xml }

      it { is_expected.to have_http_status(:success) }
      it { expect(status_message.reload.deleted_at).not_to be_nil }
    end
  end
end
