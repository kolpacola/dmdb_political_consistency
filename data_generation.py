import pandas as pd
import random
from datetime import datetime, timedelta
import numpy as np

#generate 1000 random users 
users = pd.read_csv('random_names.csv')

# Convert index to a column with a specific name
users.index.name = 'User_ID'
users = users.reset_index()

#generate random time stamp for each user for the year 2025
start = datetime(2025, 1, 1)
end = datetime(2025, 12, 31)
post_timestamps = [start + timedelta(seconds=np.random.randint(0, int((end-start).total_seconds()))) for _ in range(5000)] 

#generate random values for the 3 text analysis scores 
polarization_score = [random.uniform(-1, 1) for _ in range(5000)]
populism_score = [random.uniform(0, 1) for _ in range(5000)]
lef_right_score = [random.uniform(0, 2) for _ in range(5000)]

#create a dataframe with the generated data
posts = pd.DataFrame({    
    'Timestamp': post_timestamps,
    'Polarization Score': polarization_score,
    'Populism Score': populism_score,
    'Left-Right Score': lef_right_score
    
})

# Create lognormal probabilities for users
user_ids = users['User_ID'].tolist()
weights = np.random.lognormal(mean=0, sigma=1.5, size=len(user_ids))
probabilities_users = weights / weights.sum()

# Assign User_IDs with lognormal distribution
posts['User_ID'] = np.random.choice(user_ids, size=5000, p=probabilities_users)

#create post IDs
posts.index.name = 'Post_ID'
posts = posts.reset_index()

# Generate reshares with realistic constraints
reshare_list = []

# Setup lognormal distribution for post popularity
post_ids = posts['Post_ID'].tolist()
weights = np.random.lognormal(mean=0, sigma=1.5, size=len(post_ids))
probabilities_posts = weights / weights.sum()

# Track which user-post combinations already exist to prevent duplicates
reshared_combinations = set()

# Generate 20000 reshares with constraints
attempts = 0
max_attempts = 50000  # Prevent infinite loop

while len(reshare_list) < 20000 and attempts < max_attempts:
    attempts += 1
    
    # Select a post with lognormal probability
    post_id = np.random.choice(post_ids, p=probabilities_posts)
    
    # Select a user with lognormal probability
    user_id = np.random.choice(user_ids, p=probabilities_users)
    
    # Get original post info
    original_post = posts[posts['Post_ID'] == post_id].iloc[0]
    original_timestamp = original_post['Timestamp']
    original_user = original_post['User_ID']
    
    # Constraint 1: Don't allow users to reshare their own posts
    if user_id == original_user:
        continue
    
    # Constraint 2: Prevent duplicate reshares (same user, same post)
    if (user_id, post_id) in reshared_combinations:
        continue
    
    # Constraint 3: Reshare timestamp must be after original post   
    time_diff = (end - original_timestamp).total_seconds()
    if time_diff <= 0:
        continue
    
    random_seconds = np.random.randint(0, int(time_diff))
    reshare_timestamp = original_timestamp + timedelta(seconds=random_seconds)
    
    # Add to list and track combination
    reshare_list.append({
        'Timestamp': reshare_timestamp,
        'Post_ID': post_id,
        'User_ID': user_id
    })
    reshared_combinations.add((user_id, post_id))

# Create dataframe for reshares
reshares = pd.DataFrame(reshare_list)

# Generate follows between users with realistic constraints
follows_list = []

for user_id in user_ids:
    num_follows = np.random.poisson(lam=10)
    user_follows = set()  # Track who this user already follows (outside loop!)
    
    attempts = 0
    while len(user_follows) < num_follows and attempts < 1000:
        attempts += 1
        followee_id = np.random.choice(user_ids, p=probabilities_users)
        
        # Constraint 1: Users cannot follow themselves
        if followee_id == user_id:
            continue
        
        # Constraint 2: Prevent duplicate follows
        if followee_id in user_follows:
            continue
        
        # Add follow relationship
        follows_list.append({
            'Follower_ID': user_id,
            'Followee_ID': followee_id
        })
        user_follows.add(followee_id)

# Create dataframe for follows
follows = pd.DataFrame(follows_list)

#save dataframes to csv files
users.to_csv('users.csv', index=False)  
posts.to_csv('posts.csv', index=False)
reshares.to_csv('user_shares_post.csv', index=False)
follows.to_csv('follows.csv', index=False)

