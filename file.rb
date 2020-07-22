def next_provider
  if current_provider_id.blank?
    providers.first
  else
    providers.drop_while { |id| id != current_provider_id }[1]
  end
end

def previous_provider
  if current_provider_id.blank?
    providers.first
  else
    providers.reverse.drop_while { |id| id != current_provider_id }[1]
  end
end
