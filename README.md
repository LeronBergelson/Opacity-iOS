# Opacity iOS Client


## Set-Up:

1. Clone the Opacity Local Server from the following [Github Page](https://github.com/ronyBesp/opacity-local-server/)
2. Follow the instructions on the Opacity Local Server Git Page to get the local django server up and running
3. Once the server is running, you will need to download and set up the following libraries that Opacity uses


## Google Place API

Opacity uses the Google Place API for searching for local businesses around the user with the specified query ie. Tim Hortons.
The Google Place's API and all the associated libraries are already included in this Xcode project. 

If you wish to update the Google Place API please follow the instructions on [Google's page to download the latest API](https://developers.google.com/places/ios-api/start#step-2-install-the-api)

To get the Google Place API to work you must obtain a key. To obtain a key for the API please follow Step 3 of the [following guide](https://developers.google.com/places/ios-api/start#step-2-install-the-api)

Once you have obtained an API key head over to the Xcode project and in the AppDelegate.m file within the didFinishLaunchingWithOptions method
you will see a comment indicating where to paste the key that you obtained from Google.


Once you have made this modification the Google Place API is ready to use for the Opacity project :) 



## Facebook API

Opacity uses the Facebook API for seamless account and user creation. By default the Xcode project provided does not have the Facebook SDK installed.

To install the SDK please follow the steps described in the [Facebook iOS SDK Guide](https://developers.facebook.com/docs/ios/getting-started) up until Step 5 (Step 5 and 6 done in the code already)

**Please note:** You will need to create a Facebook app for this as described in Step 1. It will be a private app for now (unless you decide to make it public).
If you leave the Facebook app as private make sure to add the users that will be logging into it ie. yourself, friends who can play with the app, etc..
otherwise it will not let them log in.



## Running the App

Once you have completed the pre-requisite steps described above you can now run the app with the server in the simulator. 
You will not be able to run the app on your phone currently as you are using a local server so unless you proxy your phone to your computer your phone won't know
about the server. If you place the local server on a active web server then you will be able to run the app from any phone and connect to the server.

Ensure that the local server is up and running (instructions found on the [Opacity Server page](https://github.com/ronyBesp/opacity-local-server)) and you should be able to run Opacity on the iOS Simulator without a hitch :)



## Questions/Contact

Please feel free to contact us with any questions about either the set-up/installation process or any aspect of the code or app. We always love hearing from people.

Enjoy :)

