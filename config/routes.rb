Rails.application.routes.draw do
  get 'rooms/join'
  get 'rooms/show' => 'rooms#show'
  root 'rooms#join'
end
