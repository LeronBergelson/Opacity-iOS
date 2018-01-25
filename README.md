# Opacity iOS Client

## About Opacity:
Ever wondered how busy a certain place is? Ever drove 20 minutes to a restaurant only to find out it was extremely full? Well, no more! Welcome to Opacity. The app that will solve this overlooked problem for everyone. Opacity is a service where users update how busy the place they are currently at is. Other users can see when places have last been updated as well as what the last update status was. And it's all user and community based! When users update the capacity of a business, users will receive points. These points can be used to enter in various prize draws on the opacityapp website, if a certain point threshold is reached. More exciting features with the points to follow in the Phase 2 rollout. More information on the point system can be seen on the opacityapp.com website. Opacity aims to bring people together. It aims to create a community of users where everyone helps one another by constantly providing the capacity of the place people are currently at, in order to help other users make smart decisions on where to go.

![newyork](https://user-images.githubusercontent.com/19450714/35369532-4bf18100-0156-11e8-811f-997b064f200b.png)

## Getting Started:

#### Home Screen:
Opacity's first tab, the popular tab, is the first thing users will see when they open the app. Choose from 9 preset popular categories and find businesses around you. These categories include Restaurants, Bars and Pubs, Desserts, Cinemas, Lounges and many more! Clicking on any category will find all the businesses around you and their associated current capacities! Be informed with your choice. Choose a place that fits your mood whether that be a local coffee shop that is empty or a bar full of people on a Friday night. Opacity has you covered.

![main-vertical](https://user-images.githubusercontent.com/19450714/35369531-4be14e98-0156-11e8-951a-630286584186.png)


#### Search:
Searching for any business is easy. Simply type what you would like to search in the search bar and voila. Opacity will find what you are looking for with the given radius you specified in Settings (by default this is 5 km). Opacity understands what you type! You can type a business name if you know where you wanna go such as Starbucks, or a search category such as a bar to find nearby bars. Opacity will display your results in both the map and the table. Instantly see when businesses have been last updated as well as what their capacity value was. Red is High. Yellow is Medium. Blue is Low. It's that simple! Tap on either the annotation or cell in the table view to go to Apple Maps and receive directions. Opacity automatically sorts your results by distance from closest to furthest from you within your specified radius! If you encounter a business whose capacity has never been updated you will see an N/A beside it. Be sure to visit it if possible and update to help grow the community and help other users be informed! Oh and if you update an N/A business you get 5 points, instead of 1!


## Filters:
Set various filters in Settings to make your searches more efficient! Select whether you would like Opacity to only display businesses with a certain capacity level such as Low, Medium or High. Or if you would like to see all businesses regardless of which of the 3 capacities they have select the N/A filter. By default, the N/A filter is used so that users can see all businesses in their searches. In addition, be sure to specify the radius of your search to get the best results! Search radius goes from 1 to 20 km! Oh and those cool points - read on below to see how to collect them and what you can do with them! 
![newyork2](https://user-images.githubusercontent.com/19450714/35369533-4c173dfa-0156-11e8-874e-44a399123faa.png)


## Place Recognition:

At Opacity its all about brining people together. Users update their current location at any business to help others know current capacity. When clicking on the Opacity tab you will be directed to a map that will automaticly find your current location. Opacity will also recognize if you are at a specific business and ask you to update its capacity. Users can also manually update their current location by holding down on any selected business if the user is found to be within 100m from the business. Updating any business would result in a gain of user points. 
![iphone-7-plus-silver-vertical](https://user-images.githubusercontent.com/19450714/35369529-4bc2bed8-0156-11e8-8237-cd2e86ae5326.png)

## Recently Searched:

Opacity also keeps track off your last 10 searches so you can always find that place you were looking for earlier!
![recent](https://user-images.githubusercontent.com/19450714/35369535-4c2f8752-0156-11e8-926b-ce59b489531c.png)


## Meet the team:

Opacity was created by Rony Besprozvanny a Queen's University Computer Engineering student and Leron Bergelson a Game Programming student at George Brown College.

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
