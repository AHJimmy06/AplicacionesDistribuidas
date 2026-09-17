using ProgramacionDisrtibuidaC.Models;

namespace ProgramacionDisrtibuidaC.Interfaces
{
    public interface IProduct
    {
        Task<List<Product>> GetAllAsync();

        Task<Product?> GetByIdAsync(int id);

        Task UpdateAsync(
            Product product,
            byte[] versions);
    }
}