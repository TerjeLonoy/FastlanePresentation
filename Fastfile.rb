# This is the minimum version number required.
# Update this, if you use features of a newer version
fastlane_version "1.100.0"
default_platform :ios

################
# Define reusables
################

def crashlytics_api_token
    "YOUR_CRASHLYTICS_TOKEN"
end

def crashlytics_secret
    "YOUR_CRASHLYTICS_SECRET"
end

def app_scheme
    "YOUR_APP_SCHEME"
end

def upload_crashlytics
  crashlytics(
    api_token: crashlytics_api_token,
    build_secret: crashlytics_secret,
    notes: changelog_from_git_commits,
    notifications: true,
    groups: ['YOUR_TEST_GROUP']
  )
end

################
# Define lanes
################

platform :ios do
  before_all do
    ENV["SLACK_URL"] = "YOUR_SLACK_URL"
  end

  # DEPLOY DEV
  desc "Deploying to development environment through Crashlytics"
  lane :deploy_dev do
      match(app_identifier: "com.yourcompany.yourapp", type: "development")
      cocoapods
      scan
      increment_build_number

      gym(
        scheme: app_scheme,
        configuration: "Dev",
        export_method: "ad-hoc"
      )

      upload_crashlytics
      slack(message: "Application with development environment successfully deployed to crashlytics!")
  end

  # FETCH METADATA
  desc "Fetching metadata and screenshots from existing application in App Store"
  lane :get_store do
      sh "cd .. && deliver init"
  end

  # SHOWCASE METADATA
  desc "Generating summary of how application will look on AppStore"
  lane :look_store do
      snapshot
      # frameit here if you want to
      sh "cd .. && deliver generate_summary"
  end

  # UPLOAD TO APP STORE
  desc "Uploading application to iTunesConnect for review before releasing to AppStore"
    lane :deploy_store do
    match(app_identifier: "com.yourcompany.yourapp", type: "appstore")
    cocoapods
    scan
    increment_build_number

    gym(
      scheme: app_scheme,
      configuration: "Live"
    )

    deliver(
      skip_deploy: true
    )

    slack(message: "App is going live! Go get some coffee people")
  end

  after_all do |lane|
    # This block is called, only if the executed lane was successful
  end

  error do |lane, exception|
    slack(
      message: exception.message,
      success: false
    )
  end
end
