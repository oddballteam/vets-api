# frozen_string_literal: true

class SavedClaim::CaregiversAssistanceClaim < SavedClaim
  FORM = '10-10CG'

  def process_attachments!
    # Inherited from SavedClaim. Disabling since this claim does not require attachements.
    raise NotImplementedError, 'Not Implemented for Form 10-10CG'
  end

  def to_pdf
    # Inherited from SavedClaim. Disabling until it's implemented for 10-10CG (requires code in PDFFill::Filler)
    raise NotImplementedError, 'Not Implemented for Form 10-10CG'
  end

  # SavedClaims require regional_office to be defined, CaregiversAssistanceClaim has no purpose for it.
  #
  # CaregiversAssistanceClaims are not processed regional VA offices.
  # The claim's form will contain a "Planned Clinic" (a VA facility that the end-user provided in the form).
  # This facility is where the end-user's point of contact will be for post-submission processing.
  def regional_office
    []
  end

  def form_subjects
    form.nil? ? [] : parsed_form.keys
  end

  def veteran_data
    parsed_form['veteran'] unless form.nil?
  end

  def primary_caregiver_data
    parsed_form['primaryCaregiver'] unless form.nil?
  end

  def secondary_caregiver_one_data
    parsed_form['secondaryCaregiverOne'] unless form.nil?
  end

  def secondary_caregiver_two_data
    parsed_form['secondaryCaregiverTwo'] unless form.nil?
  end
end
