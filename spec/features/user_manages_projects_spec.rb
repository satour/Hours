require "spec_helper"

feature "User manages projects" do
  let(:subdomain) { generate(:subdomain) }
  let(:user) { build(:user) }

  before(:each) do
    create(:account_with_schema, subdomain: subdomain, owner: user)
    sign_in_user(user, subdomain: subdomain)
  end

  scenario "creates a project" do
    click_link "New Project"

    fill_in "Name", with: "My new project"
    click_button "Create Project"
    expect(page).to have_content(I18n.t('project_created'))
  end

  scenario "can not create a project with a new name" do
    click_link "New Project"

    fill_in "Name", with: ""
    click_button "Create Project"
    expect(page).to have_content("Please review the problems below")
  end

  scenario "go to the edit page of a project" do
    project = create(:project)
    visit project_url(project, subdomain: subdomain)
    click_link "edit"
    expect(current_url).to eq(edit_project_url(project, subdomain: subdomain))
  end

  scenario "edit a project" do
    new_project_name = "A new project name"
    project = create(:project)
    visit edit_project_url(project, subdomain: subdomain)
    fill_in "Name", with: new_project_name
    click_button "Update Project"
    expect(page).to have_content(new_project_name)
  end

  scenario "edit a project with invalid data" do
    project = create(:project)
    visit edit_project_url(project, subdomain: subdomain)
    fill_in "Name", with: ""
    click_button "Update Project"
    expect(page).to have_content("can't be blank")
  end

  scenario "does not have access to other accounts projects" do
    create(:project)
    expect(Project.count).to eq(1)

    user = build(:user)
    subdomain2 = "#{subdomain}2"
    create(:account_with_schema, subdomain: subdomain2, owner: user)
    sign_in_user(user, subdomain: subdomain2)
    expect(Project.count).to eq(0)
  end

  scenario "displays a list of projects" do
    create(:project, name: "Hours")
    create(:project, name: "Capollo13")

    visit root_url(subdomain: subdomain)
    within ".projects" do
      expect(page).to have_content("Hours")
      expect(page).to have_content("Capollo13")
    end
  end

  scenario "will paginate projects" do
    8.times do
      create(:project)
    end

    visit root_url(subdomain: subdomain)

    within ".pagination" do
      expect(page).to have_content("1 2 Next")
    end
  end

  scenario "views a single project" do
    project = create(:project_with_entries)
    entry = project.entries.last
    entry.update(description: "#TDD")

    visit root_url(subdomain: subdomain)
    within ".projects-overview" do
      click_link project.name
    end
    expect(current_url).to eq(project_url(project, subdomain: subdomain))
    expect(page).to have_content("TDD")
  end

  scenario "views a single project with more" \
           "than the maximum shown categories" do
    project = create(:project_with_more_than_maximum_entries)

    visit project_url(project, subdomain: subdomain)

    expect(page).to have_content(I18n.t("category.remaining"))
  end

  scenario "views a single project with" \
           "less then the maximum shown categories" do
    project = create(:project_with_entries)

    visit project_url(project, subdomain: subdomain)

    expect(page).not_to have_content(I18n.t("category.remaining"))
  end

  scenario "views his own hours" do
    project = create(:project)
    create(:entry, project: project, user: user, description: "#refactoring")

    visit root_url(subdomain: subdomain)
    click_link "My Hours"

    expect(page).to have_content(project.name)
    expect(page).to have_content(project.entries.last.category.name)
    expect(page).to have_content("refactoring")
  end
end
