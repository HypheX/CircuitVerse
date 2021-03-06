class Project < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_many :forks , class_name: 'Project', foreign_key: 'forked_project_id', dependent: :nullify
  belongs_to :forked_project , class_name: 'Project' , optional: true
  has_many :stars , dependent: :destroy
  has_many :user_ratings, through: :stars , dependent: :destroy ,source: 'user'
  belongs_to :assignment , optional: true

  mount_uploader :image_preview, ImagePreviewUploader

  acts_as_commontable
  # after_commit :send_mail, on: :create

  def check_edit_access(user)
    @user_access = (!user.nil? and self.author_id == user.id and self.project_submission != true)
  end

  def check_view_access(user)
    @user_access = (self.project_access_type != "Private" or (!user.nil? and self.author_id==user.id) or (!user.nil? and !self.assignment_id.nil? and self.assignment.group.mentor_id==user.id) or (!user.nil? and user.admin))
  end


  def check_direct_view_access(user)
    @user_access = (self.project_access_type == "Public" or (self.project_submission == false and  !user.nil? and self.author_id==user.id) or (!user.nil? and user.admin))
  end

  def increase_views(user)

    if user.nil? or user.id != self.author_id
      self.view ||=0
      self.view += 1
      self.save
    end
  end


  def send_mail
    if(self.forked_project_id.nil?)
      if(self.project_submission == false)
        UserMailer.new_project_email(self.author,self).deliver_later
      end
    else
      if(self.project_submission == false)
        UserMailer.forked_project_email(self.author,self.forked_project,self).deliver_later
      end
    end
  end


  validate :check_validity

  private
  def check_validity
    if project_access_type != "Private" and !assignment_id.nil?
      errors.add(:project_access_type, "Assignment has to be private")
    end
  end


end
