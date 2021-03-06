require "spec_helper"

feature "User view tags overview" do
  let(:subdomain) { generate(:subdomain) }
  let(:user) { build(:user) }

  scenario "views a tag overview" do
    create(:account_with_schema, subdomain: subdomain, owner: user)
    sign_in_user(user, subdomain: subdomain)

    tag = create(:tag)
    project = create(:project)
    entry = create(:entry, user: user, project: project, hours: 6)
    entry.tags << tag
    create(:entry, user: user, project: project, hours: 6).tags << tag

    click_link "Projects"
    click_link tag.name

    hours_indication = I18n.t("tags.show.hours_indication")
    expect(page).to (
      have_content("#{tag.name} - 12 #{hours_indication}"))
    expect(page).to have_content(entry.project.name)
    expect(page).to have_content(entry.hours)
    expect(page).to have_content(user.full_name)
    expect(page).to have_content(tag.name)
  end
end
