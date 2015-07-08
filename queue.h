#ifndef     __QUEUE_H_
#define    __QUEUE_H_ 

struct prior_queue
{

	 int *path;
	 int allocation;
	 int level;  
	 int lower_bound;
	 struct prior_queue *next; 

};

typedef struct prior_queue* PRIOR_QUEUE_T; 

void init_prior_queue(PRIOR_QUEUE_T *queue); 

PRIOR_QUEUE_T allocate_prior_queue();

void insert_prior_queue(PRIOR_QUEUE_T item , PRIOR_QUEUE_T *queue ); 

void delete_prior_queue(PRIOR_QUEUE_T *item , PRIOR_QUEUE_T *queue ); 


void add_path(int choice, PRIOR_QUEUE_T *queue , int max_len); 

void dump_queue( PRIOR_QUEUE_T queue); 

#endif 
