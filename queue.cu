#include "queue.h"
#include <stdlib.h> 
#include <stdio.h>



void init_prior_queue(PRIOR_QUEUE_T *queue)
{
    
	*queue = NULL ; 

}

void insert_prior_queue( PRIOR_QUEUE_T item , PRIOR_QUEUE_T *queue)
{


	PRIOR_QUEUE_T iter  = *queue , prev=NULL; 
	if ( *queue  == NULL ) 
	{
                    (*queue) = item ; 
		    (*queue)->next = NULL;  
                     return;   

	}
	else
	{
	     while(  (iter != NULL)  && item->lower_bound  >=  iter->lower_bound  ) 
	     {
                 
		    prev = iter;  
		    iter = iter->next;  
	                

	     }
	     if ( prev == NULL ) 
	     {

	             item->next = iter;
		     (*queue) = item;   
	     
	     }
	     else if ( iter != NULL )
	     {

                                 
               	     item->next = iter; 
	             prev->next = item ;   		   
		    

	     }
	     else
	     {
	        
		    prev->next = item ; 
	     
	     }
	
	}
	
}
void delete_prior_queue( PRIOR_QUEUE_T *item , PRIOR_QUEUE_T *queue)
{


	
	if ( *queue  == NULL ) 
	{
                      return;   

	}
	else
	{
	          item = queue ; 
		  (*queue) = (*queue)->next;   

	}
	
}



PRIOR_QUEUE_T allocate_prior_queue()
{
        struct prior_queue *queue = (struct prior_queue *) malloc( sizeof ( struct prior_queue )) ; 
        if ( queue == NULL )
	{

		fprintf(stderr , "Unable to allcate memory !" ); 
		exit(EXIT_FAILURE); 
	}


	queue->next = NULL; 
        return queue;      

}

void add_path(int choice , PRIOR_QUEUE_T *queue , int max_len)
{
        if ( (*queue)->level  <  max_len ) 
	{
           	(*queue)->path[(*queue)->level] = choice; 
	        (*queue)->level  = (*queue)->level + 1; 

	
	}

}


void free_queue(PRIOR_QUEUE_T *queue ) 
{
       PRIOR_QUEUE_T iter = *queue ; 
       PRIOR_QUEUE_T prev; 
       while( iter != NULL )
       {
               prev  = iter; 
	       
	       iter = iter->next; 
               if ( prev != NULL )
		     free(prev);   

       }


}



void dump_queue(PRIOR_QUEUE_T queue ) 
{

    PRIOR_QUEUE_T iter = queue ; 
    int count  = 0 ; 
    printf("\n >>>  -- QUEUE BEGINS  --- << "); 
    while ( iter != NULL ) 
    {

	    printf("\n>-------------------------------------------------------<\n"); 
	    printf( " \n lower bound =  %d level = %d"  , iter->lower_bound  , iter->level) ; 
	    count  = 0 ; 
	    printf(" Path = "  ); 
	    while  ( count < iter->level )
	    {
                 printf("\t%d" , iter->path[count]);  
	         count++; 

	    } 
	    printf("\n>-------------------------------------------------------<\n"); 
            printf ( "\n ");
	    iter = iter->next;    
	    
    }
    printf("\n >>> QUEUE ENDS << "); 
	
}



#ifdef  TESTQ
int main()
{

   
       int path[] = { 1 , 2, 3, -1 , -1 , -1 , -1 , -1} ;        
       PRIOR_QUEUE_T queue, item; 
       init_prior_queue(&queue); 
       queue  = allocate_prior_queue () ; 
       queue->path = path; 
       queue->level=3; 
       queue->lower_bound = 10; 
       
       
       init_prior_queue(&item); 
       item  = allocate_prior_queue () ; 
       item->path = path; 
       
       dump_queue(&queue);
       item->level=3; 
       item->lower_bound = 20; 
       
       
       insert_prior_queue(item,&queue); 
          
       init_prior_queue(&item); 
       item  = allocate_prior_queue () ; 
       item->path = path; 
       item->level=3; 
       item->lower_bound = 12; 
       add_path(10,&item,7);
       insert_prior_queue(item,&queue); 
       
       init_prior_queue(&item); 
       item  = allocate_prior_queue () ; 
       item->path = path; 
       item->level=3; 
       item->lower_bound = 27; 
       insert_prior_queue(item,&queue); 


       init_prior_queue(&item); 
       item  = allocate_prior_queue () ; 
       item->path = path; 
       item->level=3; 
       item->lower_bound = 9; 
       insert_prior_queue(item,&queue); 



       init_prior_queue(&item); 
       item  = allocate_prior_queue () ; 
       item->path = path; 
       item->level=3; 
       item->lower_bound = 19; 



            

       insert_prior_queue(item,&queue); 


       init_prior_queue(&item); 
       item  = allocate_prior_queue () ; 
       item->path = path; 
       item->level=3; 
       item->lower_bound = 17; 
       insert_prior_queue(item,&queue); 


       delete_prior_queue(&item,&queue);

       dump_queue(&queue);  
	// priority queue testing done , here  ... 


}


#endif 
