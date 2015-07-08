#include "tsp.h"

#include <stdio.h>
#include <limits.h>






/*
 *   Function reduce_matrix_row : 
 *
 *   inputs : augmented adjacent matrix and size  
 *
 *   outputs: reduced matrix given , row and column , selection 
 *
 *
 */

__global__ void reduce_matrix_row( int *aug_adj_mat ,int offset ,  int row , int col,  int size , int dim)
{

  
     int count  = 0 ;    	
     int span_size = gridDim.x * blockDim.x; 
     int tid =   threadIdx.x; 
     int min_so_far;
     int iter = 0 ; 
     int val; 
     int total_count = size / span_size + 1; 
     int *mat = (aug_adj_mat + offset); 
     if ( (row >= 0) && (col >= 0 ) )
     {
              //*choice_val = get_i_j(mat,row,col,dim);
	      set_i_j(&mat,col,row,dim,2*INFINITE);

	    
	     for ( iter = 0 ; iter  < size ; iter++)
	     {

		    set_i_j(&mat,iter,col,dim,2*INFINITE);
		    set_i_j(&mat,row,iter,dim,2*INFINITE);
	            set_i_j(&mat,iter,iter,dim,2*INFINITE);
                    
 	      

	     }
     }
     for ( count = 0 ; count < total_count ; count++)
     {

         tid = threadIdx.x + count * span_size + blockIdx.x * blockDim.x; 

	 if ( tid < size ) 
	 {
                     min_so_far = get_i_j(mat, tid , 0 , dim ) ; 
		     for ( iter = 1 ; iter < size ; iter++)
		     {
		            min_so_far =   minimum(get_i_j(mat,tid, iter,dim) , min_so_far);
		     
		     }

		     // if infinity then ignore 
		     if ( min_so_far >= INFINITE )
		     {

			   min_so_far =  0;    
		     }
		     set_i_j(&mat,tid,size,dim,min_so_far); 
                     for ( iter  = 0 ; iter < size ; iter++)
		     {
			  val = get_i_j ( (mat), tid, iter , dim); 
			  
			  if ( val <=  INFINITE )
			     set_i_j(&mat, tid, iter, dim, val - min_so_far); 

		      
		     }
		     
                   
	 }

     
     }


}	
/*
 *   Function reduce_matrix_col : 
 *
 *   inputs : augmented adjacent matrix and size  
 *
 *   outputs: reduced matrix given , row and column , selection 
 *
 *
 */


__global__ void reduce_matrix_col( int *aug_adj_mat,int offset, int row , int col,  int size , int dim )
{

  
     int count  = 0 ;    	
     int span_size = gridDim.x * blockDim.x; 
     int tid =   threadIdx.x; 
     int min_so_far;
     int iter = 0 ; 
     int val; 
     int total_count = size / span_size + 1;
     
     int *mat = (aug_adj_mat + offset); 

     for ( count = 0 ; count < total_count ; count++)
     {

         tid = threadIdx.x + count * span_size + blockIdx.x * blockDim.x; 

	 if ( tid < size ) 
	 {
                     min_so_far = get_i_j(mat,0 , tid , dim ) ; 
		     for ( iter = 1 ; iter < size ; iter++)
		     {
		            min_so_far =   minimum(get_i_j(mat,iter, tid,dim) , min_so_far);
		     
		     }
		      // if infinity then ignore 
		     if ( min_so_far >= INFINITE )
		     {

			   min_so_far =  0;    
		     }
		     
		    
		     set_i_j(&mat,size,tid,dim,min_so_far); 
                     for ( iter  = 0 ; iter < size ; iter++)
		     {
			  val = get_i_j (  mat, iter, tid , dim); 
			  if ( val <= INFINITE ) 
			      set_i_j(&mat , iter, tid,  dim, val - min_so_far); 

		      
		     }
                   
	 }

     
     }




}	


/*
 *   Function calc_lower_bound: 
 *
 *   inputs : reduced matrix , size 
 *     
 *
 *
 */


__global__ void calc_lower_bound( int *aug_adj_matx , int offset, int parent_offset, int row , int col , int size,  int dim)
{

    __shared__ int  tmp_buf[SHARED_MEM_SIZE]; 
    
     int tid = threadIdx.x + blockIdx.x * gridDim.x ; 
     int span_size = gridDim.x * blockDim.x; 
     int total_count = ( (dim-1) / span_size ) + 1 ; 
     int iter = 0 ; 
     int *red_matrix = aug_adj_matx +   offset  * dim * dim ; 
     int *par_matrix = aug_adj_matx + parent_offset * dim * dim ; 
     int lower_bound = 0 ; 
     int lbc1 = 0 , lbc2 = 0 ; 
      // initialized the shared memory buffer to  0 

     for ( iter = threadIdx.x ; iter < SHARED_MEM_SIZE ; iter += blockDim.x )
     {
                
        tmp_buf[iter] = 0 ; 
	__syncthreads(); 
     }

     for ( iter = 0 ; iter < total_count ; iter++)
     {
          if ( tid  < (size) ) 
	  {
	                
		       tmp_buf[threadIdx.x ] += get_i_j(red_matrix , tid ,size ,dim)  + get_i_j(red_matrix,size ,tid , dim); 
		       tid += span_size;  
		       __syncthreads(); 	
	  }
        	
               
     }  


     for ( iter =  blockDim.x/2 ; iter > 0 ; iter >>=1)
     {

            if ( threadIdx.x < iter ) 
	    {

	            tmp_buf[threadIdx.x] +=  tmp_buf[threadIdx.x + iter]; 
	    }
	    __syncthreads(); 

     }

     if ( threadIdx.x  == 0 )
     {

	     
	   lbc1 =  get_i_j ( par_matrix , row , col , dim);
	   lbc2 =  get_i_j ( par_matrix , size , size ,dim) ; 
	   if ( lbc1 >= INFINITE  || lbc2 >= INFINITE  )
	   {
                   lower_bound = INFINITE; 
	   } 
	   else 
	   {
                   lower_bound = lbc1 + lbc2 + tmp_buf[0];  

	   }
			   
           set_i_j(&red_matrix , size,size , dim , lower_bound);   

     }


}

__global__ void copy_matrix ( int *dest , int*src ,  int dim )
{


     int count  = 0 ;    	
     int span_size = gridDim.x * blockDim.x; 
     int tid =   threadIdx.x; 
     int iter = 0 ; 
     int total_count = dim / span_size + 1;   
     for ( count = 0 ; count < total_count ; count++)
     {

         tid = threadIdx.x + count * span_size + blockIdx.x * blockDim.x; 

	 if ( tid < dim ) 
	 {
		     for ( iter = 0 ; iter < dim ; iter++)
		     {
		             set_i_j ( &dest , tid, iter,dim, get_i_j(src,iter, tid,dim) ) ;
		     
		     }
		     
                   
	 }

     
     }

}



/*
 *   Function: get_i_j  
 *     
 *   Description : Utility function for converting a 2d array into a id array , given the row and column , returns the value at row , col 
 *   
 *
 *
 */

__device__ inline  int get_i_j( int *matrix , int row , int col , int dim)
{ 


	return matrix[row*dim+col]; 
}	

/*   
 *  Function : set_i_j  int *
 *
 *  Description: Given a matrix , row and column, dimension and value , fixes a value at i , j  
 *  
 *  
 *
 */

__device__  inline void set_i_j ( int **matrix , int row , int col , int dim, int val)
{


	(*matrix)[row*dim + col] =val; 
}	

/*__device__ int choice_val; 

 *
 *   Function: minimum 
 *
 *   Description : Given 2 number a , b returns the minuimum of the 2 
 *
 *
 *
 *
 */

__device__ inline int minimum( int val1 ,int  val2)
{ 


         if ( val1 < val2) 
		 return val1;
	 return val2; 



}	



