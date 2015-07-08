#include <stdio.h>
#include <stdlib.h> 

#include "tsp.h"
#include "queue.h" 


#define KILOB  (1024) 
#define MEGB  (KILOB * KILOB ) 
#define GIGA  ( KILOB * MEGB )  


enum
{
   FALSE,
   TRUE

};


/* Allocation megabytes on GPU */ 
#define  GPU_ALLOC  ( 512 * MEGB)


// remove this remove test code 
#define TEST 

void allocate_adj_matrix( int **mat , char *filename, int dim, int mat_size ); 
void copy_matrix_to_device ( int *matrix , int dim , int **cuda_mat); 
void copy_matrix_to_host( int **matrix , int dim ,int *cuda_mat); 
void dump_matrix ( int *mat , int size) ;

void copy_matrix_to_offset( int start_offset , int dest_offset , int dim ); 
int  extract_lower_bound ( int *mat ,int size ,  int dim ); 

void solve_tsp(PRIOR_QUEUE_T queue , int *adj_matrix , int dim);

inline void evaluate_path(int *parent,int *child  , PRIOR_QUEUE_T queue , int dim); 
void solve_tsp2(PRIOR_QUEUE_T queue , int *adj_matrix , int dim);

int is_visted( int *path, int len , int vertex);

/*
     globals 

*/

int __current_allocation = 0 ; 
int *__cudaMatrix; 


int main()
{


        int *matrix; 
        cudaError_t err; 
        PRIOR_QUEUE_T queue;   
        int *dev_mat_ptr;
	int lb; 
	int *dev_ptr; 

        // Allocat a huge array  in GPU for our matrix 

        err = cudaMalloc( (void**)&__cudaMatrix , GPU_ALLOC);


        if ( err != cudaSuccess )
        {
            fprintf(stderr,"\n Unable to allocate cuda  ( GPU men for our matrix ) memory !");
	    exit(EXIT_FAILURE); 
    
    
        }
        init_prior_queue(&queue);    	
  



	// Define a test variable at the top , for testing .. 

        #ifdef TEST    	
	     init_prior_queue(&queue); 
	     allocate_adj_matrix(&matrix,(char *)"test.txt",5,4);
             dump_matrix(matrix,5); 
             copy_matrix_to_device(matrix , 5 , &__cudaMatrix ); 
             reduce_matrix_row<<<1, 1>>>(__cudaMatrix,0,1,2,4,5); 
             reduce_matrix_col<<<1, 1>>>(__cudaMatrix,0,1,2,4,5); 	 
             calc_lower_bound<<<1,1024>>>(__cudaMatrix, 0 ,__cudaMatrix, 0 , 1 , 2 , 4 ,  5 ) ; 
	     lb = extract_lower_bound(__cudaMatrix,4,5); 
             printf( " \n lower bound = %d" , lb); 
	     cudaMalloc( (void **)&dev_ptr , 25* sizeof(int)); 
             copy_matrix<<<10,10>>>(dev_ptr,__cudaMatrix, 5);      
	     copy_matrix_to_host(&matrix , 5, dev_ptr);
             cudaDeviceSynchronize();
	     printf("\n Reduced Matrix ... \n"); 
	     dump_matrix(matrix,5);
	     
	     allocate_adj_matrix(&matrix,(char *)"test.txt",5,4);
	     solve_tsp2(queue,matrix,5);
            #endif 	     
        
	     
         free(matrix); 
}



void allocate_adj_matrix ( int **mat , char *filename , int dim , int mat_size)
{

    int *adj_matrix = (int *) malloc(sizeof(int) * dim * dim ); 
    
    FILE *fp = fopen ( filename , "r");
    memset(adj_matrix , 0 , sizeof(int) * dim * dim ); 
    if ( fp == NULL  ) 
    {
          fprintf(stderr, " Unable to open the file !");
	  exit(EXIT_FAILURE);

    }
    int row , col ; 
    for ( row = 0 ; row < mat_size ; row++)
    {
	    for ( col = 0 ; col < mat_size ; col++)
	    {

	            fscanf(fp, "%d", &adj_matrix[row*dim + col]) ;  
	    
	    
	    }


    }
    *mat = adj_matrix; 
    fclose(fp); 
      

}

void dump_matrix ( int *mat , int dim)
{
    int row , col ; 	
   for ( row = 0 ; row < dim ; row++)
   {
       for ( col = 0 ; col < dim ; col++)
       {
 
            printf("%d\t\t\t" , mat[row*dim + col]);        
      
      
       }
       printf("\n"); 
  
  
   } 


}

void copy_matrix_to_device ( int *matrix , int dim , int **cuda_mat)
{
    cudaError_t err = cudaMalloc( (void**)cuda_mat , sizeof(int) * dim * dim);
    cudaEvent_t sync;
    cudaEventCreate(&sync); 
    if ( err != cudaSuccess )
    {
         fprintf(stderr,"\n Unable to allocate cuda memory !");
	 exit(EXIT_FAILURE); 
    
    
    }
    cudaMemset(*cuda_mat,0,dim*dim);
    cudaMemcpy(*cuda_mat,matrix , dim * dim * sizeof(int) , cudaMemcpyHostToDevice);  
    cudaEventRecord(sync,0);

}

void copy_matrix_to_host( int **matrix , int dim , int *cuda_mat)
{
    
    cudaEvent_t sync; 
    cudaEventCreate(&sync);
    cudaMemcpy(*matrix,cuda_mat , dim * dim * sizeof(int) , cudaMemcpyDeviceToHost);  
    cudaEventRecord(sync,0);
    cudaEventSynchronize(sync);       


}


int  extract_lower_bound ( int *mat ,int size ,  int dim )
{
        
     	int lower_bound; 
           
       cudaEvent_t sync; 
       cudaEventCreate(&sync);

      cudaMemcpy(&lower_bound ,   (mat   + size * dim + size) , sizeof(lower_bound) , cudaMemcpyDeviceToHost ); 	      
      cudaEventRecord(sync,0);
      cudaEventSynchronize(sync);       
      return lower_bound ; 

}	






void evaluate_path(int *parent,int *child  , PRIOR_QUEUE_T queue , int dim)
{

       
      int level =  1; 
      int temp;          	
      int vertex  = 0 ; 
      PRIOR_QUEUE_T new_item,top=NULL;
      init_prior_queue(&new_item);  
      init_prior_queue(&top);  
      int parent_lb = 0;
      int *path_so_far;
      int level_so_far;
      int lower_bound_so_far;
      path_so_far= (int *)malloc(sizeof(int) * (dim + 1) ); 
      level_so_far = queue->level ;       
      lower_bound_so_far = queue->lower_bound;
      memcpy(path_so_far,queue->path , sizeof(int) *( dim + 1));
     
       
     for ( level = 1 ; level < queue->level ; level++)
     {
    
	     
    	   
	    reduce_matrix_row<<<10,1024>>>(child,0, queue->path[level-1] , queue->path[level] ,dim-1, dim);
            reduce_matrix_col<<<10,1024>>>(child,0, queue->path[level-1] , queue->path[level] ,dim-1, dim);


     }	    

     delete_prior_queue(&top,&queue);

    
     copy_matrix<<<10,1024>>>(parent, child, dim);    

       
     for ( vertex = 0 ; vertex < dim ; vertex++)
      {
         
	 if ( vertex != path_so_far[level_so_far - 1])
	 {	 
		 new_item = allocate_prior_queue();
		 new_item->path = (int *)malloc(sizeof(int) * (dim + 1) ) ; 
		 memcpy(new_item->path,path_so_far, sizeof(int) *( dim + 1));
		 new_item->level = level_so_far; 
		 add_path(vertex , &new_item, dim);
		 reduce_matrix_row<<<10,1024>>>(child,0, new_item->path[new_item->level-1] , new_item->path[new_item->level-1] ,dim-1, dim);
		 reduce_matrix_col<<<10,1024>>>(child,0, new_item->path[new_item->level-1] , new_item->path[new_item->level-1] ,dim-1, dim);
		 calc_lower_bound<<<1,1024>>>(child, 0 ,parent, 0 ,  new_item->path[new_item->level-1] , new_item->path[new_item->level], dim-1,dim); 
		 cudaDeviceSynchronize(); 
		 new_item->lower_bound = extract_lower_bound(child,dim-1,dim) +  lower_bound_so_far; 	 
	         insert_prior_queue(new_item,&queue);


	}
      } 
   printf(" \n Evaluate --- "); 

   dump_queue(queue);
}

int is_visted( int *path, int len , int vertex)
{

    int count = 0 ;
    for ( count = 0 ; count < len; count++)
    {

        if ( path[count] == vertex )
		return TRUE;
    
    }

    return FALSE; 
}



void solve_tsp2(PRIOR_QUEUE_T queue , int *adj_matrix , int dim)
{


         int *cu_child , *cu_parent,  *cu_red; 
         PRIOR_QUEUE_T new_item,top; 
         int temp;
	 int done = 0;

         int level =  1; 
         int vertex  = 0 ; 
         init_prior_queue(&new_item);  
         init_prior_queue(&top);  
         int parent_lb = 0;
         int *path_so_far;
         int level_so_far;
         int lower_bound_so_far;
         int temp_lb;       

	 copy_matrix_to_device(adj_matrix , dim , &cu_parent); 
         copy_matrix_to_device(adj_matrix, dim, &cu_child);    	 
         copy_matrix_to_device(adj_matrix,dim, &cu_red);

	 init_prior_queue(&new_item); 
  
	 // Calculate reduced matrix  
	 reduce_matrix_row<<<10,1024>>>(cu_child,0, -1 , -1 ,dim-1, dim);
         reduce_matrix_col<<<10,1024>>>(cu_child,0, -1,  -1 ,dim-1, dim);
	 calc_lower_bound<<<1,1024>>>(cu_child, 0 ,cu_parent, 0 ,  dim-1 , dim-1 , dim-1,dim); 
         copy_matrix<<<10,1024>>>(cu_red,cu_child, dim); 
	 new_item = allocate_prior_queue(); 
         new_item->path = (int *)malloc(sizeof(int) * ( dim  + 1) ) ; 
	 new_item->level = 0;
	 new_item->lower_bound =  extract_lower_bound(cu_child,dim-1,dim);  
         add_path(0,&new_item,dim); 
         insert_prior_queue(new_item , &queue); 	 
             
	 while(!done )
	 {

                
	      path_so_far= (int *)malloc(sizeof(int) * (dim + 1) ); 
	      level_so_far = queue->level ;       
	      lower_bound_so_far = queue->lower_bound;
	      memcpy(path_so_far,queue->path , sizeof(int) *( dim + 1));
	     
	     copy_matrix<<<10,1024>>>(cu_child,cu_red,dim); 
	     for ( level = 1 ; level < queue->level ; level++)
	     {
	    
		     
		   
		    reduce_matrix_row<<<10,1024>>>(cu_child,0, queue->path[level-1] , queue->path[level] ,dim-1, dim);
		    reduce_matrix_col<<<10,1024>>>(cu_child,0, queue->path[level-1] , queue->path[level] ,dim-1, dim);


	     }	    

	     delete_prior_queue(&top,&queue);

	    
	     copy_matrix<<<10,1024>>>(cu_parent,cu_child, dim);    

	       
	     for ( vertex = 0 ; vertex < dim-1 ; vertex++)
	      {
		 
		 if (is_visted(path_so_far,level_so_far,vertex)==FALSE)
		 {	 
			 new_item = allocate_prior_queue();
			 new_item->path = (int *)malloc(sizeof(int) * (dim + 1) ) ; 
			 memcpy(new_item->path,path_so_far, sizeof(int) *( dim + 1));
			 new_item->level = level_so_far; 
			 add_path(vertex , &new_item, dim);
			 reduce_matrix_row<<<10,1024>>>(cu_child,0, new_item->path[new_item->level-1] , new_item->path[new_item->level-1] ,dim-1, dim);
			 reduce_matrix_col<<<10,1024>>>(cu_child,0, new_item->path[new_item->level-1] , new_item->path[new_item->level-1] ,dim-1, dim);
			 calc_lower_bound<<<1,1024>>>(cu_child, 0 ,cu_parent, 0 ,  new_item->path[new_item->level-1] , new_item->path[new_item->level], dim-1,dim); 
			 cudaDeviceSynchronize(); 
		
		         temp_lb =  extract_lower_bound(cu_child,dim-1,dim) ;
			 if( temp_lb >= INFINITE || lower_bound_so_far >= INFINITE ) 
			      new_item->lower_bound = INFINITE; 
		         else

			 new_item->lower_bound = temp_lb  +  lower_bound_so_far; 	 
			
		         insert_prior_queue(new_item,&queue);


		}
	      }       
	     dump_queue(queue);
	     if ( queue == NULL ) 
			break;
	     if ( queue->level == dim-1)
		break;

	 }


	dump_queue(queue);
 	


}




void solve_tsp(PRIOR_QUEUE_T queue , int *adj_matrix , int dim)
{

         int *cu_child , *cu_parent; 
         PRIOR_QUEUE_T new_item,top; 
         int temp;
	 int done = 0;
	 copy_matrix_to_device(adj_matrix , dim , &cu_parent); 
         copy_matrix_to_device(adj_matrix, dim, &cu_child);    	 
         init_prior_queue(&new_item); 
  
	 // Calculate reduced matrix  
	 reduce_matrix_row<<<10,1024>>>(cu_child,0, -1 , -1 ,dim-1, dim);
         reduce_matrix_col<<<10,1024>>>(cu_child,0, -1,  -1 ,dim-1, dim);
	 calc_lower_bound<<<1,1024>>>(cu_child, 0 ,cu_parent, 0 ,  dim-1 , dim-1 , dim-1,dim); 

	 new_item = allocate_prior_queue(); 
         new_item->path = (int *)malloc(sizeof(int) * ( dim  + 1) ) ; 
	 new_item->level = 0;
	 new_item->lower_bound =  extract_lower_bound(cu_child,dim-1,dim);  
         add_path(0,&new_item,dim); 
         insert_prior_queue(new_item , &queue); 	 
         while(!done )
	 {

                evaluate_path(cu_parent , cu_child, queue , dim );
	       
               	dump_queue(queue);
		if ( queue == NULL ) 
			break;
		if ( queue->level == dim-1)
			break;

	 }


	dump_queue(queue);
 	 

}
