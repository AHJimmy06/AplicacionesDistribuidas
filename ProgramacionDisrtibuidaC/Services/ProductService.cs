using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using ProgramacionDisrtibuidaC.Interfaces;
using ProgramacionDisrtibuidaC.Models;

namespace ProgramacionDisrtibuidaC.Services
{
    public class ProductService
    {
        private readonly IProduct _repo;

        public ProductService(IProduct repo)
        {
            _repo = repo;
        }

        public async Task<List<Product>> GetAllAsync()
        {
            return await _repo.GetAllAsync();
        }

        public async Task<Product?> GetByIdAsync(int id)
        {
            return await _repo.GetByIdAsync(id);
        }

        public async Task UpdateAsync(
            int id,
            Product product,
            byte[] versions)
        {
            if (id != product.Id)
            {
                throw new ArgumentException(
                    "El Id no coincide.");
            }

            Validar(product);

            try
            {
                await _repo.UpdateAsync(
                    product,
                    versions);
            }
            catch (DbUpdateConcurrencyException)
            {
                throw new InvalidOperationException(
                    "Conflicto de concurrencia: otro usuario modificó el producto antes.");
            }
        }

        private static void Validar(Product product)
        {
            var context = new ValidationContext(product);

            Validator.ValidateObject(
                product,
                context,
                validateAllProperties: true);
        }
    }
}