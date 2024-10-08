# VixVox

VixVox is a dynamic social media platform designed specifically for movie and show lovers. Whether you're looking to keep track of your favorite movies and shows, discover new trends, or connect with friends who share your interests, VixVox has you covered.
## Features

- Wishlist: Create and manage a wishlist of movies and shows you want to watch.
- Discover: Find new and trending movies and shows with our discovery feature.
- Social Integration: Follow friends to see their movie and show ratings, reviews, and wishlists.
- Ratings & Reviews: Rate movies and shows, and share your thoughts with the VixVox community.
- Personalized Feed: Stay updated with a personalized feed that highlights your friends' activities and trending content.

## Technologies Used

**Client:** Flutter: A UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. VixVox uses Flutter to create a seamless and responsive user interface.
   
**Server:**  Firebase: Provides various backend services including real-time database, authentication, and cloud storage. VixVox utilizes Firebase for user authentication, data storage, and real-time updates.

**APIs:** TMDb (The Movie Database): An API service that provides access to a vast collection of movies, TV shows, and related information. VixVox uses TMDb to fetch movie and show data, including details, ratings, and trending content using REST API.
**Other Tools:**
- REST API: Uses REST API to fetch TMDB data. 
- Dart: The programming language used with Flutter to build the app.
- Firebase Authentication: For handling user sign-up, login, and authentication processes.
- Firebase Firestore: For storing user data, including wishlists, ratings, and reviews.
- Firebase Cloud Storage: For storing user profile pictures and other media content.
- Firebase Analytics: For tracking user interactions and app usage.
## Usage/Examples

### Create an Account
Get Started by clicking on Sign Up here then fill out necessary information. Validate your email address by clicking on the link sent to the given email.
<div><img src="readme_photos/create_account_page.png" alt="Create an Account" width="300"/></div>


### Login
Login to the account by providing email and password.
<div><img src="readme_photos\login_page.png" alt="Login page" width="300"/></div>


### Search
Find your favourite movies by writing your favourite movie's name. Click on the provided movie.
<div style="display: flex; flex-direction: row;">
<img src="readme_photos\search_page.png" alt="Login page" width="300"/>
   <img src="readme_photos\search_results.png" alt="Login page" width="300"/>
 
</div>


### Adding to Wishlist
You can also add your Movies/Tv Shows to wishlist by clicking on the "+" button with your favourite wishlist as the name.

<div style="display: flex; flex-direction: row;">
   <img src="readme_photos\wishlist_movies.png" alt="Login page" width="300"/>  <img src="readme_photos\add_a_new_wishlist.png" alt="Login page" width="300"/>
   
</div>

### Discovering new Movies/Tv Shows
You can find your new Movies or Tv Shows by scrolling the discover page.
<div><img src="readme_photos\discover_page.png" alt="Login page" width="300"/></div>

### Write A Review
Write a review by clicking on the discussion tab of your favourite Movies or Tv Shows.

<div style="display: flex; flex-direction: row;">
   <img src="readme_photos\movie_details.png" alt="Login page" width="300"/>
      <img src="readme_photos\movie_discussion.png" alt="Login page" width="300"/>
</div>

## Authors

- Hussain Merchant: mhussum@gmail.com
## Acknowledgements

- VixVox recognizes that it uses TMDB API to fetch movies and tvshows to show its users movies and tvshows information
- VixVox also Acknowledgements that it uses JustWatch to fullfill watch provider requirement for their users.

