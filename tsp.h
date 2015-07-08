#ifndef _TSP_H_ 
#define _TSP_H_ 

#include <limits.h> 



#define INFINITE  (INT_MAX/2) 
#define SHARED_MEM_SIZE   1024




/*
 *   Function reduce_matrix_row : 
 *
 *   inputs : augmented adjacent matrix and size  
 *
 *   outputs: reduced matrix given , row and column , selection 
 *
 *
 */


__global__ void reduce_matrix_row( int *aug_adj_mat ,  int offset , int row , int col,  int size , int dim); 

/*
 *   Function reduce_matrix_col : 
 *
 *   inputs : augmented adjacent matrix and size  
 *
 *   outputs: reduced matrix given , row and column , selection 
 *
 *
 */


__global__ void reduce_matrix_col( int *aug_adj_mat , int offset , int row , int col,  int size , int dim ); 


/*
 *   Function calc_lower_bound: 
 *
 *   inputs : reduced matrix , size 
 *   
 *
 *
 */


__global__ void calc_lower_bound( int *aug_adj_matx , int offset, int *parent, int parent_offset,int row , int col,int size,  int dim);


   
__global__ void copy_matrix ( int *dest , int*src ,  int dim );






/*
 *   Function: get_i_j  cudaEvent_t sync; 

 *     
 *   Description : Utility function for converting a 2d array into a id array , given the row and column , returns the value at row , col 
 *   
 *
 *
 */

__device__  inline int get_i_j( int *matrix , int row , int col , int dim);  

/*   
 *  Function : set_i_j 
 *
 *  Description: Given a matrix , row and column, dimension and value , fixes a value at i , j  
 *  
 *  
 *
 */

__device__ inline void set_i_j ( int **matrix , int row , int col , int dim, int value); 

/*
 *
 *   Function: minimum 
 *
 *   Description : Given 2 number a , b returns the minuimum of the 2 
 *
 *
 *
 *
 */

__device__ inline  int minimum( int val1 ,int  val2); 


#endif 



