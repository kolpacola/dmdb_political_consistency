CREATE TABLE users (
	id serial4 NOT NULL,
	last_name varchar(50) NULL,
	first_name varchar(50) NULL,
	CONSTRAINT users_pkey PRIMARY KEY (id)
);

CREATE TABLE posts (
	id serial4 NOT NULL,
	user_id int4 NOT NULL,
	"content" text NULL,
	created_at timestamp NULL,
	left_right_score float8 NULL,
	populism_score float8 NULL,
	affective_polarization float8 NULL,
	CONSTRAINT chk_posts_affective CHECK (((affective_polarization >= ('-1.0'::numeric)::double precision) AND (affective_polarization <= (1.0)::double precision))),
	CONSTRAINT chk_posts_left_right CHECK (((left_right_score >= (0.0)::double precision) AND (left_right_score <= (2.0)::double precision))),
	CONSTRAINT chk_posts_populism CHECK (((populism_score >= (0.0)::double precision) AND (populism_score <= (1.0)::double precision))),
	CONSTRAINT posts_pkey PRIMARY KEY (id),
	CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE user_shares_post (
	id int4 DEFAULT nextval('project.share_id_seq'::regclass) NOT NULL,
	user_id int4 NOT NULL,
	post_id int4 NOT NULL,
	"timestamp" timestamp NULL,
	CONSTRAINT share_pkey PRIMARY KEY (id),
	CONSTRAINT fk_share_post FOREIGN KEY (post_id) REFERENCES posts(id),
	CONSTRAINT fk_share_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE follows (
	follower_id int4 NOT NULL,
	followed_id int4 NOT NULL,
	CONSTRAINT chk_follows_not_self CHECK ((follower_id <> followed_id)),
	CONSTRAINT pk_follows PRIMARY KEY (follower_id, followed_id),
	CONSTRAINT fk_follows_followed FOREIGN KEY (followed_id) REFERENCES users(id),
	CONSTRAINT fk_follows_follower FOREIGN KEY (follower_id) REFERENCES users(id)
);